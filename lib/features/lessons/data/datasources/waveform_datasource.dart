import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audio_trim.dart';
import '../models/waveform_peaks.dart';

/// Источник пиков волны для отрисовки.
abstract interface class WaveformDataSource {
  /// [cache] выключают для файла, который ещё не принадлежит приложению
  /// (выбранное, но не импортированное аудио): рядом с чужим файлом мусорить
  /// нельзя, пики считаются на один показ.
  ///
  /// [range] — отрезок файла, который пойдёт на волну. Разрешение постоянное,
  /// поэтому у обрезанной дорожки на её длину приходятся все [resolution]
  /// отсчётов: иначе от файла в час на 73 секунды урока досталась бы пара сотен
  /// отсчётов, и паузы между фразами размазались бы в кашу. `null` — файл
  /// целиком.
  Future<WaveformPeaks> loadPeaks(
    String audioPath, {
    int resolution = kWaveformResolution,
    bool cache = true,
    AudioTrim? range,
  });
}

/// Реализация на `just_waveform`. Результат извлечения кешируется рядом с
/// аудио в файле `<audioPath>.wave`, чтобы не считать пики при каждом открытии.
class JustWaveformDataSource implements WaveformDataSource {
  const JustWaveformDataSource();

  @override
  Future<WaveformPeaks> loadPeaks(
    String audioPath, {
    int resolution = kWaveformResolution,
    bool cache = true,
    AudioTrim? range,
  }) async {
    // Извлечение идёт по файлу целиком и кешируется целиком: отрезок вырезаем
    // уже из готовых пикселей, это дёшево.
    final waveform = await _obtainWaveform(audioPath, cache);
    return _resample(waveform, resolution, range);
  }

  Future<Waveform> _obtainWaveform(String audioPath, bool cache) async {
    // Извлечению всё равно нужен файл на выходе, поэтому без кеша пишем во
    // временный каталог и убираем за собой.
    final cacheFile = cache
        ? File('$audioPath.wave')
        : File(
            p.join(
              Directory.systemTemp.path,
              'shado-preview-${DateTime.now().microsecondsSinceEpoch}.wave',
            ),
          );
    if (cache && await cacheFile.exists()) {
      try {
        return await JustWaveform.parse(cacheFile);
      } catch (_) {
        // Битый кеш — считаем заново.
        await cacheFile.delete();
      }
    }
    try {
      final progress = JustWaveform.extract(
        audioInFile: File(audioPath),
        waveOutFile: cacheFile,
        zoom: const WaveformZoom.pixelsPerSecond(100),
      );
      final result = await progress.firstWhere(
        (event) => event.waveform != null,
      );
      return result.waveform!;
    } catch (error) {
      throw AudioFailure('Не удалось построить волновую форму', cause: error);
    } finally {
      if (!cache) {
        try {
          if (await cacheFile.exists()) await cacheFile.delete();
        } catch (_) {
          // Временный файл не удалился — не повод рушить показ волны.
        }
      }
    }
  }

  /// Прореживает пики отрезка [range] до [resolution] столбиков и нормализует
  /// их к `-1..1`.
  WaveformPeaks _resample(Waveform waveform, int resolution, AudioTrim? range) {
    final pixels = waveform.length;
    if (pixels <= 0) {
      return const WaveformPeaks(minima: [], maxima: []);
    }
    var start = 0;
    var end = pixels;
    if (range != null) {
      start = waveform
          .positionToPixel(Duration(milliseconds: range.startMs))
          .floor()
          .clamp(0, pixels - 1);
      end = waveform
          .positionToPixel(Duration(milliseconds: range.endMs))
          .ceil()
          .clamp(start + 1, pixels);
    }
    final span = end - start;
    final buckets = math.min(resolution, span);
    final scale = waveform.flags == 0 ? 32768.0 : 128.0;
    final minima = List<double>.filled(buckets, 0);
    final maxima = List<double>.filled(buckets, 0);

    for (var bucket = 0; bucket < buckets; bucket++) {
      final from = start + span * bucket ~/ buckets;
      final to = math.max(from + 1, start + span * (bucket + 1) ~/ buckets);
      var minValue = 0;
      var maxValue = 0;
      for (var i = from; i < to; i++) {
        minValue = math.min(minValue, waveform.getPixelMin(i));
        maxValue = math.max(maxValue, waveform.getPixelMax(i));
      }
      minima[bucket] = (minValue / scale).clamp(-1.0, 0.0);
      maxima[bucket] = (maxValue / scale).clamp(0.0, 1.0);
    }
    return WaveformPeaks(minima: minima, maxima: maxima);
  }
}

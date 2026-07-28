import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audio_trim.dart';
import '../models/waveform_peaks.dart';

/// Что рисуем: аудио на сервере, его локальная копия (если уже скачана) и
/// отрезок, который должен занять всю ширину волны.
///
/// [audioId] нужен серверному источнику, [localPath] — локальным: первому пики
/// считает сервер, вторым нужен сам файл.
class WaveformQuery {
  const WaveformQuery({
    required this.audioId,
    this.localPath,
    this.durationMs = 0,
    this.resolution = kWaveformResolution,
    this.range,
    this.cache = true,
  });

  final String audioId;

  /// Путь к скачанному файлу; `null` — файла ещё нет, и остаётся только сервер.
  final String? localPath;

  /// Длительность файла целиком: по ней серверные пики переводятся в
  /// миллисекунды при вырезании [range].
  final int durationMs;

  final int resolution;

  /// Отрезок файла, который пойдёт на волну. `null` — файл целиком.
  final AudioTrim? range;

  /// Локальным источникам: писать ли кеш пиков рядом с файлом. У чужого файла,
  /// ещё не принадлежащего приложению, кеш не создаём.
  final bool cache;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaveformQuery &&
          other.audioId == audioId &&
          other.localPath == localPath &&
          other.durationMs == durationMs &&
          other.resolution == resolution &&
          other.range == range &&
          other.cache == cache;

  @override
  int get hashCode =>
      Object.hash(audioId, localPath, durationMs, resolution, range, cache);
}

/// Источник пиков волны для отрисовки.
///
/// Основная реализация — серверная (`RemoteWaveformDataSource`): волна выходит
/// одинаковой на Android, iOS и Windows. Локальные остаются запасным путём,
/// когда сервер недоступен, а файл уже скачан.
abstract interface class WaveformDataSource {
  Future<WaveformPeaks> loadPeaks(WaveformQuery query);
}

/// Вырезает из готовых пиков отрезок [range] и отдаёт его как самостоятельную
/// волну.
///
/// Серверные пики приходят на файл целиком, а показать иногда нужно кусок:
/// на десятиминутном файле обрезанной минуте досталась бы пара сотен отсчётов,
/// и паузы между фразами слились бы в кашу.
WaveformPeaks slicePeaks(
  WaveformPeaks peaks,
  AudioTrim? range,
  int durationMs,
) {
  if (range == null || durationMs <= 0 || peaks.isEmpty) return peaks;
  if (!range.isTrimmedFrom(durationMs)) return peaks;

  final total = peaks.length;
  final from = (total * range.startMs ~/ durationMs).clamp(0, total - 1);
  final to = (total * range.endMs / durationMs).ceil().clamp(from + 1, total);
  return WaveformPeaks(
    minima: peaks.minima.sublist(from, math.min(to, peaks.minima.length)),
    maxima: peaks.maxima.sublist(from, to),
  );
}

/// Реализация на `just_waveform` для Android/iOS. Результат извлечения
/// кешируется рядом с аудио в файле `<audioPath>.wave`, чтобы не считать пики
/// при каждом открытии.
class JustWaveformDataSource implements WaveformDataSource {
  const JustWaveformDataSource();

  @override
  Future<WaveformPeaks> loadPeaks(WaveformQuery query) async {
    final audioPath = query.localPath;
    if (audioPath == null) {
      throw const AudioFailure('Файл ещё не скачан — волну строить не из чего');
    }
    // Извлечение идёт по файлу целиком и кешируется целиком: отрезок вырезаем
    // уже из готовых пикселей, это дёшево.
    final waveform = await _obtainWaveform(audioPath, query.cache);
    return _resample(waveform, query.resolution, query.range);
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

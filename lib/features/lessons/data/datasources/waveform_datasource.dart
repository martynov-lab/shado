import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:just_waveform/just_waveform.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../models/waveform_peaks.dart';

/// Источник пиков волны для отрисовки.
abstract interface class WaveformDataSource {
  Future<WaveformPeaks> loadPeaks(
    String audioPath, {
    int resolution = kWaveformResolution,
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
  }) async {
    final waveform = await _obtainWaveform(audioPath);
    return _resample(waveform, resolution);
  }

  Future<Waveform> _obtainWaveform(String audioPath) async {
    final cacheFile = File('$audioPath.wave');
    if (await cacheFile.exists()) {
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
    }
  }

  /// Прореживает пики до [resolution] столбиков и нормализует их к `-1..1`.
  WaveformPeaks _resample(Waveform waveform, int resolution) {
    final pixels = waveform.length;
    if (pixels <= 0) {
      return const WaveformPeaks(minima: [], maxima: []);
    }
    final buckets = math.min(resolution, pixels);
    final scale = waveform.flags == 0 ? 32768.0 : 128.0;
    final minima = List<double>.filled(buckets, 0);
    final maxima = List<double>.filled(buckets, 0);

    for (var bucket = 0; bucket < buckets; bucket++) {
      final from = pixels * bucket ~/ buckets;
      final to = math.max(from + 1, pixels * (bucket + 1) ~/ buckets);
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

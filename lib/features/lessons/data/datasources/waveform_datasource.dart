import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/failures.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/waveform_peaks.dart';
import '../../domain/entities/waveform_query.dart';

/// Source of waveform peaks for painting.
abstract interface class WaveformDataSource {
  Future<WaveformPeaks> loadPeaks(WaveformQuery query);
}

/// Slices [range] out of ready peaks as a standalone waveform.
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

/// Peaks via `just_waveform` on Android/iOS; the result is cached in
/// `<audioPath>.wave`.
class JustWaveformDataSource implements WaveformDataSource {
  const JustWaveformDataSource();

  @override
  Future<WaveformPeaks> loadPeaks(WaveformQuery query) async {
    final audioPath = query.localPath;
    if (audioPath == null) {
      throw const AudioFailure('The file is not downloaded yet — nothing to build a waveform from');
    }
    // Extract and cache the whole file; the range is sliced from ready peaks.
    final waveform = await _obtainWaveform(audioPath, query.cache);
    return _resample(waveform, query.resolution, query.range);
  }

  Future<Waveform> _obtainWaveform(String audioPath, bool cache) async {
    // Extraction needs an output file — without caching use a temp directory.
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
        // A broken cache is recomputed.
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AudioFailure('Failed to build the waveform', cause: error),
        stackTrace,
      );
    } finally {
      if (!cache) {
        try {
          if (await cacheFile.exists()) await cacheFile.delete();
        } catch (_) {
          // The temporary file was not removed — the waveform still works.
        }
      }
    }
  }

  /// Downsamples peaks of [range] to [resolution] bars and normalizes them
  /// to `-1..1`.
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

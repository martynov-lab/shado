import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audio_trim.dart';
import '../models/waveform_peaks.dart';

/// Peaks query: which audio to build and which range to show.
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

  /// Path to the downloaded file; `null` when it is missing.
  final String? localPath;

  /// Duration of the whole file.
  final int durationMs;

  final int resolution;

  /// File range for the waveform; `null` means the whole file.
  final AudioTrim? range;

  /// Whether to write the peaks cache next to the file.
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
      throw const AudioFailure('Файл ещё не скачан — волну строить не из чего');
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
    } catch (error) {
      throw AudioFailure('Не удалось построить волновую форму', cause: error);
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

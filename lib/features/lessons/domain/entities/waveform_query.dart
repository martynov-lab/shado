import '../../../../core/constants/app_constants.dart';
import 'audio_trim.dart';

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

import '../../../../core/error/failures.dart';
import '../models/waveform_peaks.dart';
import 'audio_remote_datasource.dart';
import 'waveform_datasource.dart';

/// Peaks from the server, falling back to a local source when it is down.
class RemoteWaveformDataSource implements WaveformDataSource {
  const RemoteWaveformDataSource(this._remote, {WaveformDataSource? fallback})
    : _fallback = fallback;

  /// Peaks request resolution when only a file range is shown.
  static const int _slicedResolution = 4000;

  final AudioRemoteDataSource _remote;
  final WaveformDataSource? _fallback;

  @override
  Future<WaveformPeaks> loadPeaks(WaveformQuery query) async {
    try {
      final peaks = await _remote.peaks(
        query.audioId,
        resolution: query.range == null ? query.resolution : _slicedResolution,
      );
      return slicePeaks(peaks, query.range, query.durationMs);
    } on NetworkFailure {
      final fallback = _fallback;
      if (fallback == null || query.localPath == null) rethrow;
      return fallback.loadPeaks(query);
    }
  }
}

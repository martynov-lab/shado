import '../entities/waveform_peaks.dart';
import '../entities/waveform_query.dart';

/// Waveform peaks for painting an audio file or a part of it.
abstract interface class WaveformRepository {
  Future<WaveformPeaks> loadPeaks(WaveformQuery query);
}

import '../../../../core/error/failures.dart';
import '../models/waveform_peaks.dart';
import 'audio_remote_datasource.dart';
import 'waveform_datasource.dart';

/// Пики считает сервер: одна огибающая на все платформы.
///
/// Побочный эффект, ради которого всё и делалось, — волна выглядит одинаково
/// на Android, iOS и Windows, и десктопу больше не нужен собственный декодер.
///
/// [_fallback] — локальный источник на случай, когда сервера нет, а файл уже
/// скачан: без сети урок всё равно открывается и играет.
class RemoteWaveformDataSource implements WaveformDataSource {
  const RemoteWaveformDataSource(this._remote, {WaveformDataSource? fallback})
    : _fallback = fallback;

  /// Разрешение, в котором просим пики, когда показываем не весь файл: вырезать
  /// отрезок придётся из того, что пришло, поэтому берём с запасом. Потолок
  /// сервера — 4000 точек на файл, больше он всё равно не отдаст.
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

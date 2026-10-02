import '../../domain/entities/waveform_peaks.dart';
import '../../domain/entities/waveform_query.dart';
import '../../domain/repositories/waveform_repository.dart';
import '../datasources/waveform_datasource.dart';

class WaveformRepositoryImpl implements WaveformRepository {
  const WaveformRepositoryImpl(this._dataSource);

  final WaveformDataSource _dataSource;

  @override
  Future<WaveformPeaks> loadPeaks(WaveformQuery query) =>
      _dataSource.loadPeaks(query);
}

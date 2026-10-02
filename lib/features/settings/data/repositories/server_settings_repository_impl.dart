import '../../domain/repositories/server_settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class ServerSettingsRepositoryImpl implements ServerSettingsRepository {
  const ServerSettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<int> getCompletionReps() => _remote.getCompletionReps();

  @override
  Future<int> setCompletionReps(int reps) => _remote.setCompletionReps(reps);
}

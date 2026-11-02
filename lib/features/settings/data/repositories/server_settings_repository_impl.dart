import '../../domain/entities/tts_provider_settings.dart';
import '../../domain/repositories/server_settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class ServerSettingsRepositoryImpl implements ServerSettingsRepository {
  const ServerSettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<TtsProviderSettings> getTtsProvider() => _remote.getTtsProvider();

  @override
  Future<TtsProviderSettings> setTtsProvider(String name) =>
      _remote.setTtsProvider(name);
}

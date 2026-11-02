import '../../../../core/network/api_client.dart';
import '../../domain/entities/tts_provider_settings.dart';

/// Service settings; everyone reads them, the owner edits.
abstract interface class SettingsRemoteDataSource {
  Future<TtsProviderSettings> getTtsProvider();

  /// Switches the voice-over provider for all users and returns the result.
  Future<TtsProviderSettings> setTtsProvider(String name);
}

class ApiSettingsRemoteDataSource implements SettingsRemoteDataSource {
  const ApiSettingsRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<TtsProviderSettings> getTtsProvider() async {
    final json = await _client.get('/v1/settings');
    return TtsProviderSettings.fromJson(json);
  }

  @override
  Future<TtsProviderSettings> setTtsProvider(String name) async {
    final response = await _client.patch(
      '/v1/settings',
      data: {'tts_provider': name},
    );
    return TtsProviderSettings.fromJson(response.data!);
  }
}

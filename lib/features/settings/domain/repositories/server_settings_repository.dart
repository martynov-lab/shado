import '../entities/tts_provider_settings.dart';

/// Settings stored on the server and shared by all users.
abstract interface class ServerSettingsRepository {
  Future<TtsProviderSettings> getTtsProvider();

  /// Returns what the server actually saved.
  Future<TtsProviderSettings> setTtsProvider(String name);
}

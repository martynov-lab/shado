import 'dart:async';

import '../entities/tts_provider_settings.dart';
import '../repositories/server_settings_repository.dart';

/// The AI voice-over provider; only the owner switches it, for all users.
class TtsProviderService {
  TtsProviderService(this._repository);

  final ServerSettingsRepository _repository;
  final StreamController<TtsProviderSettings> _changes =
      StreamController.broadcast();

  TtsProviderSettings? _settings;

  /// `null` until the first successful load.
  TtsProviderSettings? get settings => _settings;

  Stream<TtsProviderSettings> get changes => _changes.stream;

  Future<TtsProviderSettings> load() async {
    final settings = await _repository.getTtsProvider();
    _apply(settings);
    return settings;
  }

  Future<void> change(String name) async =>
      _apply(await _repository.setTtsProvider(name));

  void dispose() => _changes.close();

  void _apply(TtsProviderSettings settings) {
    _settings = settings;
    _changes.add(settings);
  }
}

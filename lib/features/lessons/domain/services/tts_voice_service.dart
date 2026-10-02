import 'dart:async';

import '../../../languages/domain/services/language_service.dart';
import '../entities/tts_voice_selection.dart';
import '../repositories/tts_voice_settings_repository.dart';

/// The voice-over voice and accent, picked in settings and used when a lesson
/// is voiced. Every change is applied at once, saved and sent to [changes].
class TtsVoiceService {
  TtsVoiceService({
    required TtsVoiceSettingsRepository repository,
    required LanguageService languages,
  }) : _repository = repository,
       _languages = languages;

  final TtsVoiceSettingsRepository _repository;
  final LanguageService _languages;
  final StreamController<TtsVoiceSelection> _changes =
      StreamController.broadcast();

  TtsVoiceSelection _selection = const TtsVoiceSelection();
  Future<TtsVoiceSelection>? _loading;

  /// Empty until [load] completes.
  TtsVoiceSelection get selection => _selection;

  Stream<TtsVoiceSelection> get changes => _changes.stream;

  /// Reads the saved choice once.
  Future<TtsVoiceSelection> load() => _loading ??= _restore();

  Future<void> selectVoice(String voice) =>
      _update(_selection.copyWith(voice: voice));

  Future<void> selectAccent(String accent) =>
      _update(_selection.copyWith(accent: accent));

  /// The accent to send: the chosen one while it belongs to the studied
  /// language, otherwise none.
  String? accentForRequest() {
    final accents = _languages.currentAccents;
    if (accents.isEmpty) return null;
    final selected = _selection.accent;
    return accents.any((accent) => accent.code == selected) ? selected : null;
  }

  void dispose() => _changes.close();

  Future<TtsVoiceSelection> _restore() async {
    _apply(await _repository.load());
    return _selection;
  }

  Future<void> _update(TtsVoiceSelection next) async {
    _apply(next);
    await _repository.save(next);
  }

  void _apply(TtsVoiceSelection selection) {
    _selection = selection;
    _changes.add(selection);
  }
}

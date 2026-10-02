import '../entities/tts_voice_selection.dart';

/// Keeps the chosen voice-over voice and accent on the device.
abstract interface class TtsVoiceSettingsRepository {
  /// Nothing chosen (or a storage failure) gives an empty selection: the
  /// server then picks the voice itself.
  Future<TtsVoiceSelection> load();

  Future<void> save(TtsVoiceSelection selection);
}

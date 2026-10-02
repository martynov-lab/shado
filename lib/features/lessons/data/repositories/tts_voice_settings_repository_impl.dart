import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/tts_voice_selection.dart';
import '../../domain/repositories/tts_voice_settings_repository.dart';

class TtsVoiceSettingsRepositoryImpl implements TtsVoiceSettingsRepository {
  static const String _voiceKey = 'tts_voice';
  static const String _accentKey = 'tts_accent';

  @override
  Future<TtsVoiceSelection> load() async {
    try {
      final storage = await SharedPreferences.getInstance();
      return TtsVoiceSelection(
        voice: storage.getString(_voiceKey),
        accent: storage.getString(_accentKey),
      );
    } on Exception {
      return const TtsVoiceSelection();
    }
  }

  /// A failed write is ignored: the choice still works until the app
  /// restarts.
  @override
  Future<void> save(TtsVoiceSelection selection) async {
    try {
      final storage = await SharedPreferences.getInstance();
      final voice = selection.voice;
      final accent = selection.accent;
      if (voice != null) await storage.setString(_voiceKey, voice);
      if (accent != null) await storage.setString(_accentKey, accent);
    } on Exception {
      return;
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/playback_settings.dart';
import '../../domain/repositories/playback_settings_repository.dart';

class PlaybackSettingsRepositoryImpl implements PlaybackSettingsRepository {
  static const String _speedKey = 'playback_default_speed';
  static const String _repeatsKey = 'playback_repeats_in_cycle';
  static const String _pauseKey = 'playback_pause_between_repeats';
  static const String _countdownKey = 'playback_countdown_enabled';

  @override
  Future<PlaybackSettings> load() async {
    try {
      final storage = await SharedPreferences.getInstance();
      return PlaybackSettings(
        defaultSpeed: storage.getDouble(_speedKey) ?? kNormalSpeed,
        repeatsInCycle: storage.getInt(_repeatsKey) ?? kDefaultRepeatsInCycle,
        pauseBetweenRepeats: storage.getBool(_pauseKey) ?? true,
        countdownEnabled: storage.getBool(_countdownKey) ?? false,
      );
    } on Exception {
      return const PlaybackSettings();
    }
  }

  /// A failed write is ignored: the setting still works until the app
  /// restarts.
  @override
  Future<void> save(PlaybackSettings settings) async {
    try {
      final storage = await SharedPreferences.getInstance();
      await storage.setDouble(_speedKey, settings.defaultSpeed);
      await storage.setInt(_repeatsKey, settings.repeatsInCycle);
      await storage.setBool(_pauseKey, settings.pauseBetweenRepeats);
      await storage.setBool(_countdownKey, settings.countdownEnabled);
    } on Exception {
      return;
    }
  }
}

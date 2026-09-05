import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/playback_settings.dart';

/// Playback settings persisted to disk.
class PlaybackSettingsController extends AsyncNotifier<PlaybackSettings> {
  static const String _speedKey = 'playback_default_speed';
  static const String _repeatsKey = 'playback_repeats_in_cycle';
  static const String _pauseKey = 'playback_pause_between_repeats';
  static const String _countdownKey = 'playback_countdown_enabled';

  @override
  Future<PlaybackSettings> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PlaybackSettings(
        defaultSpeed: prefs.getDouble(_speedKey) ?? kNormalSpeed,
        repeatsInCycle: prefs.getInt(_repeatsKey) ?? kDefaultRepeatsInCycle,
        pauseBetweenRepeats: prefs.getBool(_pauseKey) ?? true,
        countdownEnabled: prefs.getBool(_countdownKey) ?? false,
      );
    } on Exception {
      // On a read error fall back to default values.
      return const PlaybackSettings();
    }
  }

  Future<void> setDefaultSpeed(double speed) => _update(
    (settings) => settings.copyWith(defaultSpeed: speed),
    (prefs) => prefs.setDouble(_speedKey, speed),
  );

  Future<void> setRepeatsInCycle(int repeats) {
    final clamped = repeats.clamp(kMinRepeatsInCycle, kMaxRepeatsInCycle);
    return _update(
      (settings) => settings.copyWith(repeatsInCycle: clamped),
      (prefs) => prefs.setInt(_repeatsKey, clamped),
    );
  }

  Future<void> setPauseBetweenRepeats(bool enabled) => _update(
    (settings) => settings.copyWith(pauseBetweenRepeats: enabled),
    (prefs) => prefs.setBool(_pauseKey, enabled),
  );

  Future<void> setCountdownEnabled(bool enabled) => _update(
    (settings) => settings.copyWith(countdownEnabled: enabled),
    (prefs) => prefs.setBool(_countdownKey, enabled),
  );

  /// Applies the change immediately and stores it on disk.
  Future<void> _update(
    PlaybackSettings Function(PlaybackSettings) change,
    Future<void> Function(SharedPreferences) write,
  ) async {
    final current = state.value ?? const PlaybackSettings();
    final next = change(current);
    if (next == current) return;
    state = AsyncValue.data(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await write(prefs);
    } on Exception {
      // The setting is applied; the write will not survive a restart.
    }
  }
}

final playbackSettingsControllerProvider =
    AsyncNotifierProvider<PlaybackSettingsController, PlaybackSettings>(
      PlaybackSettingsController.new,
    );

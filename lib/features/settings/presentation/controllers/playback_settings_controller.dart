import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/playback_settings.dart';

/// Настройки воспроизведения. Хранятся локально — приложение работает офлайн, и
/// выбор обязан пережить перезапуск. Плеер читает их при открытии урока и при
/// каждом запуске отрезка.
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
      // Не суметь прочитать настройки — не повод падать: работаем на дефолтах.
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

  /// Применяет изменение сразу (оптимистично) и сохраняет его. Ошибку записи
  /// гасим: значение уже действует в рантайме, просто не переживёт перезапуск.
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
      // Настройка уже применена; запись не переживёт перезапуск.
    }
  }
}

final playbackSettingsControllerProvider =
    AsyncNotifierProvider<PlaybackSettingsController, PlaybackSettings>(
      PlaybackSettingsController.new,
    );

import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../entities/playback_settings.dart';
import '../repositories/playback_settings_repository.dart';

/// Playback settings shared by the whole app. Call [load] before relying on
/// [settings]. Every change is applied at once, saved and sent to [changes].
class PlaybackSettingsService {
  PlaybackSettingsService(this._repository);

  final PlaybackSettingsRepository _repository;
  final StreamController<PlaybackSettings> _changes =
      StreamController.broadcast();

  PlaybackSettings _settings = const PlaybackSettings();
  Future<PlaybackSettings>? _loading;

  /// Defaults until [load] completes.
  PlaybackSettings get settings => _settings;

  Stream<PlaybackSettings> get changes => _changes.stream;

  /// Reads the saved settings. Safe to call many times, the storage is read
  /// only once.
  Future<PlaybackSettings> load() => _loading ??= _restore();

  Future<void> setDefaultSpeed(double speed) =>
      _update(_settings.copyWith(defaultSpeed: speed));

  /// Values outside the allowed range are clamped.
  Future<void> setRepeatsInCycle(int repeats) => _update(
    _settings.copyWith(
      repeatsInCycle: repeats.clamp(kMinRepeatsInCycle, kMaxRepeatsInCycle),
    ),
  );

  Future<void> setPauseBetweenRepeats(bool enabled) =>
      _update(_settings.copyWith(pauseBetweenRepeats: enabled));

  Future<void> setCountdownEnabled(bool enabled) =>
      _update(_settings.copyWith(countdownEnabled: enabled));

  void dispose() => _changes.close();

  Future<PlaybackSettings> _restore() async {
    _apply(await _repository.load());
    return _settings;
  }

  Future<void> _update(PlaybackSettings next) async {
    if (next == _settings) return;
    _apply(next);
    await _repository.save(next);
  }

  void _apply(PlaybackSettings settings) {
    _settings = settings;
    _changes.add(settings);
  }
}

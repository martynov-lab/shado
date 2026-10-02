import '../entities/playback_settings.dart';

/// Keeps playback settings on the device between launches.
abstract interface class PlaybackSettingsRepository {
  /// Returns the defaults when nothing is saved or the storage can't be read.
  Future<PlaybackSettings> load();

  Future<void> save(PlaybackSettings settings);
}

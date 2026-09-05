import 'package:audio_service/audio_service.dart';

import 'lesson_remote_control.dart';

/// Bridge between the system media session and the open lesson's
/// [LessonRemoteControl].
class ShadowingAudioHandler extends BaseAudioHandler {
  /// Lesson currently holding the session; `null` outside a lesson screen.
  LessonRemoteControl? _control;

  /// Hands session control to the opened lesson.
  void attach(LessonRemoteControl control) => _control = control;

  /// Releases control when the session is held by [control].
  void detach(LessonRemoteControl control) {
    if (!identical(_control, control)) return;
    _control = null;
    _publishStopped();
  }

  /// Publishes the current segment and playback state to the session.
  void setNowPlaying({
    required String id,
    required String title,
    required String album,
    required Duration duration,
    required bool playing,
  }) {
    mediaItem.add(
      MediaItem(id: id, title: title, album: album, duration: duration),
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        processingState: AudioProcessingState.ready,
        playing: playing,
      ),
    );
  }

  void _publishStopped() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  // Session buttons: play and pause both map to a single toggle.
  @override
  Future<void> play() async => _control?.remoteToggle();

  @override
  Future<void> pause() async => _control?.remoteToggle();

  @override
  Future<void> skipToNext() async => _control?.remoteNext();

  @override
  Future<void> skipToPrevious() async => _control?.remotePrevious();

  @override
  Future<void> stop() async {
    _control?.remoteStop();
    await super.stop();
  }
}

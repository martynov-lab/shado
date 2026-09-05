/// Lesson player controls driven by the system media session.
abstract interface class LessonRemoteControl {
  /// Starts or stops the current segment.
  void remoteToggle();

  /// Moves to the next segment.
  void remoteNext();

  /// Moves to the previous segment.
  void remotePrevious();

  /// Stops playback on a system command.
  void remoteStop();
}

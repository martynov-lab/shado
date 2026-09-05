/// Pending daily activity delta.
class PendingEvents {
  const PendingEvents({required this.listenedMs, required this.segmentRepeats});

  static const PendingEvents empty = PendingEvents(
    listenedMs: 0,
    segmentRepeats: 0,
  );

  final int listenedMs;
  final int segmentRepeats;

  /// Nothing to send — skip the network call.
  bool get isEmpty => listenedMs <= 0 && segmentRepeats <= 0;
}

/// Local progress counters in a separate database; minutes and repeats must
/// not be lost, so migrations here are additive only.
abstract interface class ProgressLocalDataSource {
  /// Adds one segment repeat: to the per-segment counter used for completion
  /// and to the pending daily delta.
  Future<void> bumpSegment(String lessonId, int segmentIndex);

  /// Accumulates listened milliseconds in the pending delta.
  Future<void> addListened(int ms);

  /// Lesson segment repeats: `segmentIndex → reps`.
  Future<Map<int, int>> readReps(String lessonId);

  Future<PendingEvents> readPending();

  /// Subtracts what was sent instead of resetting, so activity collected
  /// during the request is kept.
  Future<void> subtractPending(int listenedMs, int segmentRepeats);

  Future<bool> isCompletedSent(String lessonId);

  Future<void> markCompletedSent(String lessonId);

  /// Wipes all progress on sign-out.
  Future<void> clear();
}

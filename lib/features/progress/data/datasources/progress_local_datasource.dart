import '../../domain/entities/pending_events.dart';
import '../../domain/entities/progress_summary.dart';

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

  /// The last summary received from the server; `null` before the first one.
  Future<ProgressSummary?> readSummary();

  Future<void> saveSummary(ProgressSummary summary);

  /// The last daily history received from the server; `null` before the
  /// first one.
  Future<List<ProgressDay>?> readHistory();

  Future<void> saveHistory(List<ProgressDay> days);

  /// Wipes all progress on sign-out.
  Future<void> clear();
}

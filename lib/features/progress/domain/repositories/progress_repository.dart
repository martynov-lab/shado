import '../entities/pending_events.dart';
import '../entities/progress_summary.dart';

/// Learning progress: counters kept on the device and the server summary.
abstract interface class ProgressRepository {
  Future<void> addListened(int ms);

  /// Counts one repeat of the segment, both for lesson completion and for the
  /// pending daily delta.
  Future<void> bumpSegment(String lessonId, int segmentIndex);

  /// Repeats per segment of the lesson: `segmentIndex → reps`.
  Future<Map<int, int>> readReps(String lessonId);

  Future<PendingEvents> readPending();

  /// Subtracts what was sent, so activity collected during the request stays.
  Future<void> subtractPending(int listenedMs, int segmentRepeats);

  Future<bool> isCompletedSent(String lessonId);

  Future<void> markCompletedSent(String lessonId);

  /// Sends activity to the server and returns the fresh summary. Only the
  /// given fields are sent.
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  });

  Future<ProgressSummary> getSummary();

  /// Daily history for the last [days] days.
  Future<List<ProgressDay>> getHistory({int days});

  /// Wipes everything stored on the device, used on sign-out.
  Future<void> clear();
}

import '../../domain/entities/item_rating.dart';
import '../../domain/entities/pending_events.dart';
import '../../domain/entities/progress_summary.dart';

/// Local progress counters in a separate database; minutes and repeats must
/// not be lost, so migrations here are additive only.
abstract interface class ProgressLocalDataSource {
  /// Adds one segment repeat to the pending daily delta.
  Future<void> bumpSegment();

  /// Accumulates listened milliseconds in the pending delta.
  Future<void> addListened(int ms);

  /// Current ratings of the lesson: `itemKey → stars`, rated items only.
  Future<Map<String, int>> readStars(String lessonId);

  /// Saves the user's own ratings and queues them for the server.
  Future<void> saveRatings(List<ItemRating> ratings);

  /// Oldest queued ratings first, at most [limit].
  Future<List<ItemRating>> readQueuedRatings({required int limit});

  /// Takes ratings off the queue unless they were changed after [sent].
  Future<void> markRatingsSent(List<ItemRating> sent);

  /// Applies ratings from the server where they are newer than the local
  /// ones; returns the ids of lessons whose ratings changed.
  Future<Set<String>> applyServerRatings(List<ItemRating> ratings);

  /// `server_time` of the last rating delta; `null` before the first one.
  Future<String?> readRatingsSince();

  Future<void> saveRatingsSince(String serverTime);

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

import '../entities/item_rating.dart';
import '../entities/pending_events.dart';
import '../entities/progress_summary.dart';

/// Learning progress: counters kept on the device and the server summary.
abstract interface class ProgressRepository {
  Future<void> addListened(int ms);

  /// Counts one segment repeat in the pending daily delta.
  Future<void> bumpSegment();

  /// Current ratings of the lesson: `itemKey → stars`, rated items only.
  Future<Map<String, int>> readStars(String lessonId);

  /// Saves the user's ratings on the device until [syncRatings] sends them.
  Future<void> saveRatings(List<ItemRating> ratings);

  /// Sends queued ratings and pulls the ones changed on other devices;
  /// returns the ids of lessons whose ratings changed.
  Future<Set<String>> syncRatings();

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

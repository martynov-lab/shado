import 'package:shado/features/progress/domain/entities/item_rating.dart';
import 'package:shado/features/progress/domain/entities/pending_events.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/domain/repositories/progress_repository.dart';

/// An event the fake server received.
class RecordedEvent {
  RecordedEvent(
    this.listenedMs,
    this.segmentRepeats,
    this.lessonId,
    this.completed,
  );

  final int? listenedMs;
  final int? segmentRepeats;
  final String? lessonId;
  final bool? completed;
}

/// In-memory progress: local counters and ratings plus a server that records
/// events and rating syncs.
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({this.throwOnEvents = false});

  bool throwOnEvents;
  bool throwOnSync = false;
  final List<RecordedEvent> events = [];
  final List<ItemRating> savedRatings = [];
  final Set<String> completed = {};
  int listenedMs = 0;
  int segmentRepeats = 0;
  int syncCount = 0;

  /// Lessons the next sync reports as changed on another device.
  Set<String> serverChanges = {};

  @override
  Future<void> addListened(int ms) async => listenedMs += ms;

  @override
  Future<void> bumpSegment() async => segmentRepeats += 1;

  @override
  Future<Map<String, int>> readStars(String lessonId) async {
    final stars = <String, int>{};
    for (final rating in savedRatings) {
      if (rating.lessonId != lessonId) continue;
      if (rating.stars > 0) {
        stars[rating.itemKey] = rating.stars;
      } else {
        stars.remove(rating.itemKey);
      }
    }
    return stars;
  }

  @override
  Future<void> saveRatings(List<ItemRating> ratings) async =>
      savedRatings.addAll(ratings);

  @override
  Future<Set<String>> syncRatings() async {
    syncCount++;
    if (throwOnSync) throw Exception('offline');
    final changed = serverChanges;
    serverChanges = {};
    return changed;
  }

  @override
  Future<PendingEvents> readPending() async =>
      PendingEvents(listenedMs: listenedMs, segmentRepeats: segmentRepeats);

  @override
  Future<void> subtractPending(int listenedMs, int segmentRepeats) async {
    this.listenedMs = (this.listenedMs - listenedMs).clamp(0, 1 << 62);
    this.segmentRepeats = (this.segmentRepeats - segmentRepeats).clamp(
      0,
      1 << 62,
    );
  }

  @override
  Future<bool> isCompletedSent(String lessonId) async =>
      completed.contains(lessonId);

  @override
  Future<void> markCompletedSent(String lessonId) async =>
      completed.add(lessonId);

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async {
    if (throwOnEvents) throw Exception('offline');
    events.add(RecordedEvent(listenedMs, segmentRepeats, lessonId, completed));
    return ProgressSummary.fromJson(const {});
  }

  @override
  Future<ProgressSummary> getSummary() async =>
      ProgressSummary.fromJson(const {});

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async => const [];

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> clear() async {}
}

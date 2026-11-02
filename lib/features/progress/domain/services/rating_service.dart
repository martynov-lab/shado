import 'dart:async';

import '../../../auth/domain/services/auth_service.dart';
import '../entities/item_rating.dart';
import '../repositories/progress_repository.dart';
import 'progress_reporter.dart';
import 'progress_summary_service.dart';

/// Star ratings of lesson items: saved on the device first, then synced
/// with the server so every device of the user sees the same stars.
class RatingService {
  RatingService({
    required ProgressRepository repository,
    required ProgressReporter reporter,
    required ProgressSummaryService summary,
    required AuthService auth,
  }) : _repository = repository,
       _reporter = reporter,
       _summary = summary,
       _auth = auth {
    _authSubscription = _auth.changes
        .map((session) => session.isAuthenticated ? session.user?.id : null)
        .distinct()
        .where((userId) => userId != null)
        .listen((_) => unawaited(sync()));
    if (_auth.session.isAuthenticated) unawaited(sync());
  }

  final ProgressRepository _repository;
  final ProgressReporter _reporter;
  final ProgressSummaryService _summary;
  final AuthService _auth;
  final StreamController<String> _changes = StreamController.broadcast();
  late final StreamSubscription<void> _authSubscription;

  Future<void>? _syncing;
  bool _syncAgain = false;

  /// Ids of lessons whose ratings changed here or on another device.
  Stream<String> get changes => _changes.stream;

  /// Current ratings of the lesson: `itemKey → stars`, rated items only.
  Future<Map<String, int>> starsOf(String lessonId) =>
      _repository.readStars(lessonId);

  /// Gives [stars] to every item of [itemKeys]; `0` removes the rating.
  /// [lessonItemKeys] are all items of the lesson, to detect completion.
  Future<void> rate({
    required String lessonId,
    required List<String> itemKeys,
    required int stars,
    required List<String> lessonItemKeys,
  }) async {
    final now = DateTime.now().toUtc();
    await _repository.saveRatings([
      for (final key in itemKeys)
        ItemRating(lessonId: lessonId, itemKey: key, stars: stars, ratedAt: now),
    ]);
    _changes.add(lessonId);
    unawaited(
      _reporter.reportCompletedIfDone(
        lessonId: lessonId,
        itemKeys: lessonItemKeys,
      ),
    );
    unawaited(sync());
  }

  /// Sends queued ratings and pulls changes; a failure leaves them queued.
  Future<void> sync() {
    if (_syncing != null) {
      _syncAgain = true;
      return _syncing!;
    }
    return _syncing = _runSync().whenComplete(() => _syncing = null);
  }

  void dispose() {
    _authSubscription.cancel();
    _changes.close();
  }

  Future<void> _runSync() async {
    do {
      _syncAgain = false;
      try {
        final changed = await _repository.syncRatings();
        changed.forEach(_changes.add);
        // Five stars change the learned phrase counters of the summary.
        await _summary.refresh();
      } catch (_) {
        return;
      }
    } while (_syncAgain);
  }
}

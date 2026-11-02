import '../progress_math.dart';
import '../repositories/progress_repository.dart';
import 'progress_summary_service.dart';

/// Collects activity on the device and sends it to the server in batches.
/// The summary that comes back goes to [ProgressSummaryService].
class ProgressReporter {
  ProgressReporter({
    required ProgressRepository repository,
    required ProgressSummaryService summary,
  }) : _repository = repository,
       _summary = summary;

  final ProgressRepository _repository;
  final ProgressSummaryService _summary;

  bool _flushing = false;

  Future<void> addListened(int ms) => _repository.addListened(ms);

  /// Counts [count] segment repeats in the daily activity.
  Future<void> recordRepeats(int count) async {
    for (var i = 0; i < count; i++) {
      await _repository.bumpSegment();
    }
  }

  /// Sends what has piled up. [lessonId] marks the lesson as recent. On a
  /// failure the data stays on the device for the next try.
  Future<void> flush({String? lessonId}) async {
    if (_flushing) return;
    _flushing = true;
    try {
      final pending = await _repository.readPending();
      if (pending.isEmpty) return;
      final summary = await _repository.reportEvents(
        listenedMs: pending.listenedMs > 0 ? pending.listenedMs : null,
        segmentRepeats: pending.segmentRepeats > 0
            ? pending.segmentRepeats
            : null,
        lessonId: lessonId,
      );
      await _repository.subtractPending(
        pending.listenedMs,
        pending.segmentRepeats,
      );
      _summary.accept(summary);
    } catch (_) {
      return;
    } finally {
      _flushing = false;
    }
  }

  /// Sends `completed` once, after every item of [itemKeys] got five stars.
  Future<void> reportCompletedIfDone({
    required String lessonId,
    required List<String> itemKeys,
  }) async {
    try {
      if (await _repository.isCompletedSent(lessonId)) return;
      final stars = await _repository.readStars(lessonId);
      if (!progressIsComplete(stars, itemKeys)) return;
      final summary = await _repository.reportEvents(
        completed: true,
        lessonId: lessonId,
      );
      await _repository.markCompletedSent(lessonId);
      _summary.accept(summary);
    } catch (_) {
      return;
    }
  }
}

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

  /// Counts one pass of a range for each of its segments.
  Future<void> recordSegmentPass(
    String lessonId,
    Iterable<int> segmentIndices,
  ) async {
    for (final index in segmentIndices) {
      await _repository.bumpSegment(lessonId, index);
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

  /// Sends `completed` once, after every segment has been repeated
  /// [completionReps] times.
  Future<void> reportCompletedIfDone({
    required String lessonId,
    required int segmentCount,
    required int completionReps,
  }) async {
    try {
      if (await _repository.isCompletedSent(lessonId)) return;
      final reps = await _repository.readReps(lessonId);
      if (!progressIsComplete(reps, segmentCount, completionReps)) return;
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

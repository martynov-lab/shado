import '../domain/entities/progress_summary.dart';
import '../domain/progress_math.dart';
import 'datasources/progress_local_datasource.dart';
import 'datasources/progress_remote_datasource.dart';

/// Accumulates activity locally and sends it to the server in batches.
class ProgressReporter {
  ProgressReporter({
    required ProgressLocalDataSource local,
    required ProgressRemoteDataSource remote,
    this.onSummary,
  }) : _local = local,
       _remote = remote;

  final ProgressLocalDataSource _local;
  final ProgressRemoteDataSource _remote;

  /// Fresh summary that came with the server response.
  final void Function(ProgressSummary summary)? onSummary;

  bool _flushing = false;

  /// Accumulates listened milliseconds.
  Future<void> addListened(int ms) => _local.addListened(ms);

  /// Counts one range pass for each of its segments.
  Future<void> recordSegmentPass(
    String lessonId,
    Iterable<int> segmentIndices,
  ) async {
    for (final index in segmentIndices) {
      await _local.bumpSegment(lessonId, index);
    }
  }

  /// Sends the pending delta; [lessonId] marks the lesson as recent.
  Future<void> flush({String? lessonId}) async {
    if (_flushing) return;
    _flushing = true;
    try {
      final pending = await _local.readPending();
      if (pending.isEmpty) return;
      final summary = await _remote.reportEvents(
        listenedMs: pending.listenedMs > 0 ? pending.listenedMs : null,
        segmentRepeats: pending.segmentRepeats > 0
            ? pending.segmentRepeats
            : null,
        lessonId: lessonId,
      );
      // Subtract exactly what was sent — activity during the request stays.
      await _local.subtractPending(pending.listenedMs, pending.segmentRepeats);
      onSummary?.call(summary);
    } catch (_) {
      // The delta stays in the cache — retry later.
    } finally {
      _flushing = false;
    }
  }

  /// Sends `completed` once every segment has been repeated [completionReps]
  /// times.
  Future<void> reportCompletedIfDone({
    required String lessonId,
    required int segmentCount,
    required int completionReps,
  }) async {
    try {
      if (await _local.isCompletedSent(lessonId)) return;
      final reps = await _local.readReps(lessonId);
      if (!progressIsComplete(reps, segmentCount, completionReps)) return;
      final summary = await _remote.reportEvents(
        completed: true,
        lessonId: lessonId,
      );
      await _local.markCompletedSent(lessonId);
      onSummary?.call(summary);
    } catch (_) {
      // Do not set the flag — try again next time.
    }
  }
}

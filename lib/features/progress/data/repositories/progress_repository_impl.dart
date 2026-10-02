import '../../../../core/error/failures.dart';
import '../../domain/entities/pending_events.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_datasource.dart';
import '../datasources/progress_remote_datasource.dart';

/// Progress: counters on the device, the server summary with its last copy
/// kept for offline starts.
class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl({
    required ProgressLocalDataSource local,
    required ProgressRemoteDataSource remote,
  }) : _local = local,
       _remote = remote;

  final ProgressLocalDataSource _local;
  final ProgressRemoteDataSource _remote;

  @override
  Future<void> addListened(int ms) => _local.addListened(ms);

  @override
  Future<void> bumpSegment(String lessonId, int segmentIndex) =>
      _local.bumpSegment(lessonId, segmentIndex);

  @override
  Future<Map<int, int>> readReps(String lessonId) => _local.readReps(lessonId);

  @override
  Future<PendingEvents> readPending() => _local.readPending();

  @override
  Future<void> subtractPending(int listenedMs, int segmentRepeats) =>
      _local.subtractPending(listenedMs, segmentRepeats);

  @override
  Future<bool> isCompletedSent(String lessonId) =>
      _local.isCompletedSent(lessonId);

  @override
  Future<void> markCompletedSent(String lessonId) =>
      _local.markCompletedSent(lessonId);

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async {
    final summary = await _remote.reportEvents(
      listenedMs: listenedMs,
      segmentRepeats: segmentRepeats,
      lessonId: lessonId,
      completed: completed,
    );
    await _local.saveSummary(summary);
    return summary;
  }

  @override
  Future<ProgressSummary> getSummary() async {
    final ProgressSummary summary;
    try {
      summary = await _remote.getSummary();
    } on NetworkFailure {
      // Offline: the last summary received, if there is one.
      final cached = await _local.readSummary();
      if (cached == null) rethrow;
      return cached;
    }
    await _local.saveSummary(summary);
    return summary;
  }

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async {
    final List<ProgressDay> history;
    try {
      history = await _remote.getHistory(days: days);
    } on NetworkFailure {
      final cached = await _local.readHistory();
      if (cached == null) rethrow;
      return cached;
    }
    await _local.saveHistory(history);
    return history;
  }

  @override
  Future<void> clear() => _local.clear();
}

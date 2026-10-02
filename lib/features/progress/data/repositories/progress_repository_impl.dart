import '../../domain/entities/pending_events.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_datasource.dart';
import '../datasources/progress_remote_datasource.dart';

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
  }) => _remote.reportEvents(
    listenedMs: listenedMs,
    segmentRepeats: segmentRepeats,
    lessonId: lessonId,
    completed: completed,
  );

  @override
  Future<ProgressSummary> getSummary() => _remote.getSummary();

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) =>
      _remote.getHistory(days: days);

  @override
  Future<void> clear() => _local.clear();
}

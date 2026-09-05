import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/data/progress_reporter.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';

/// In-memory local storage: the test does not need sqflite.
class _FakeLocal implements ProgressLocalDataSource {
  final Map<String, Map<int, int>> reps = {};
  final Set<String> completed = {};
  int listenedMs = 0;
  int segmentRepeats = 0;

  @override
  Future<void> addListened(int ms) async => listenedMs += ms;

  @override
  Future<void> bumpSegment(String lessonId, int segmentIndex) async {
    final byIndex = reps.putIfAbsent(lessonId, () => {});
    byIndex[segmentIndex] = (byIndex[segmentIndex] ?? 0) + 1;
    segmentRepeats += 1;
  }

  @override
  Future<Map<int, int>> readReps(String lessonId) async =>
      Map.of(reps[lessonId] ?? const {});

  @override
  Future<PendingEvents> readPending() async =>
      PendingEvents(listenedMs: listenedMs, segmentRepeats: segmentRepeats);

  @override
  Future<void> subtractPending(int listenedMs, int segmentRepeats) async {
    this.listenedMs = (this.listenedMs - listenedMs).clamp(0, 1 << 62);
    this.segmentRepeats = (this.segmentRepeats - segmentRepeats).clamp(0, 1 << 62);
  }

  @override
  Future<bool> isCompletedSent(String lessonId) async =>
      completed.contains(lessonId);

  @override
  Future<void> markCompletedSent(String lessonId) async =>
      completed.add(lessonId);

  @override
  Future<void> clear() async {
    reps.clear();
    completed.clear();
    listenedMs = 0;
    segmentRepeats = 0;
  }
}

class _RecordedEvent {
  _RecordedEvent(this.listenedMs, this.segmentRepeats, this.lessonId, this.completed);
  final int? listenedMs;
  final int? segmentRepeats;
  final String? lessonId;
  final bool? completed;
}

class _FakeRemote implements ProgressRemoteDataSource {
  _FakeRemote({this.throwOnEvents = false});

  bool throwOnEvents;
  final List<_RecordedEvent> events = [];

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async {
    if (throwOnEvents) throw Exception('offline');
    events.add(_RecordedEvent(listenedMs, segmentRepeats, lessonId, completed));
    return ProgressSummary.fromJson(const {});
  }

  @override
  Future<ProgressSummary> getSummary() async =>
      ProgressSummary.fromJson(const {});

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async => const [];
}

void main() {
  group('ProgressReporter.flush', () {
    test('шлёт накопленное и вычитает отправленное', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote();
      final reporter = ProgressReporter(local: local, remote: remote);
      await local.addListened(5000);
      await local.bumpSegment('l1', 0);

      await reporter.flush(lessonId: 'l1');

      expect(remote.events.single.listenedMs, 5000);
      expect(remote.events.single.segmentRepeats, 1);
      expect(remote.events.single.lessonId, 'l1');
      // The delta is cleared after a successful upload.
      final pending = await local.readPending();
      expect(pending.isEmpty, isTrue);
    });

    test('пустую дельту не шлёт', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote();
      final reporter = ProgressReporter(local: local, remote: remote);

      await reporter.flush();

      expect(remote.events, isEmpty);
    });

    test('при сбое дельта сохраняется', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(throwOnEvents: true);
      final reporter = ProgressReporter(local: local, remote: remote);
      await local.addListened(3000);

      await reporter.flush();

      final pending = await local.readPending();
      expect(pending.listenedMs, 3000);
    });
  });

  group('ProgressReporter.reportCompletedIfDone', () {
    test('шлёт completed один раз и ставит флаг', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote();
      final reporter = ProgressReporter(local: local, remote: remote);
      // Two segments with threshold 2: both are completed.
      await local.bumpSegment('l1', 0);
      await local.bumpSegment('l1', 0);
      await local.bumpSegment('l1', 1);
      await local.bumpSegment('l1', 1);

      await reporter.reportCompletedIfDone(
        lessonId: 'l1',
        segmentCount: 2,
        completionReps: 2,
      );
      await reporter.reportCompletedIfDone(
        lessonId: 'l1',
        segmentCount: 2,
        completionReps: 2,
      );

      final completedEvents =
          remote.events.where((e) => e.completed == true).toList();
      expect(completedEvents, hasLength(1));
      expect(await local.isCompletedSent('l1'), isTrue);
    });

    test('недобитый урок не отмечается', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote();
      final reporter = ProgressReporter(local: local, remote: remote);
      await local.bumpSegment('l1', 0);

      await reporter.reportCompletedIfDone(
        lessonId: 'l1',
        segmentCount: 2,
        completionReps: 2,
      );

      expect(remote.events.where((e) => e.completed == true), isEmpty);
      expect(await local.isCompletedSent('l1'), isFalse);
    });
  });
}

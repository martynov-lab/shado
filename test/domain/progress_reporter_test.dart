import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/entities/pending_events.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/domain/repositories/progress_repository.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';

class _RecordedEvent {
  _RecordedEvent(
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

/// In-memory progress: local counters plus a server that records events.
class _FakeProgressRepository implements ProgressRepository {
  _FakeProgressRepository({this.throwOnEvents = false});

  bool throwOnEvents;
  final List<_RecordedEvent> events = [];
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
    events.add(_RecordedEvent(listenedMs, segmentRepeats, lessonId, completed));
    return ProgressSummary.fromJson(const {});
  }

  @override
  Future<ProgressSummary> getSummary() async =>
      ProgressSummary.fromJson(const {});

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async => const [];

  @override
  Future<void> clear() async {}
}

void main() {
  group('ProgressReporter.flush', () {
    test('sends what was accumulated and subtracts what was sent', () async {
      final repository = _FakeProgressRepository();
      final reporter = _makeReporter(repository);
      await repository.addListened(5000);
      await repository.bumpSegment('l1', 0);

      await reporter.flush(lessonId: 'l1');

      expect(repository.events.single.listenedMs, 5000);
      expect(repository.events.single.segmentRepeats, 1);
      expect(repository.events.single.lessonId, 'l1');
      // The delta is cleared after a successful upload.
      final pending = await repository.readPending();
      expect(pending.isEmpty, isTrue);
    });

    test('hands the fresh summary to the summary service', () async {
      final repository = _FakeProgressRepository();
      final summary = ProgressSummaryService(repository);
      addTearDown(summary.dispose);
      final reporter = ProgressReporter(
        repository: repository,
        summary: summary,
      );
      await repository.addListened(1000);

      await reporter.flush();

      expect(summary.summary, isNotNull);
    });

    test('does not send an empty delta', () async {
      final repository = _FakeProgressRepository();
      final reporter = _makeReporter(repository);

      await reporter.flush();

      expect(repository.events, isEmpty);
    });

    test('the delta survives a failure', () async {
      final repository = _FakeProgressRepository(throwOnEvents: true);
      final reporter = _makeReporter(repository);
      await repository.addListened(3000);

      await reporter.flush();

      final pending = await repository.readPending();
      expect(pending.listenedMs, 3000);
    });
  });

  group('ProgressReporter.reportCompletedIfDone', () {
    test('sends completed once and sets the flag', () async {
      final repository = _FakeProgressRepository();
      final reporter = _makeReporter(repository);
      // Two segments with threshold 2: both are completed.
      await repository.bumpSegment('l1', 0);
      await repository.bumpSegment('l1', 0);
      await repository.bumpSegment('l1', 1);
      await repository.bumpSegment('l1', 1);

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

      final completedEvents = repository.events
          .where((e) => e.completed == true)
          .toList();
      expect(completedEvents, hasLength(1));
      expect(await repository.isCompletedSent('l1'), isTrue);
    });

    test('an unfinished lesson is not marked', () async {
      final repository = _FakeProgressRepository();
      final reporter = _makeReporter(repository);
      await repository.bumpSegment('l1', 0);

      await reporter.reportCompletedIfDone(
        lessonId: 'l1',
        segmentCount: 2,
        completionReps: 2,
      );

      expect(repository.events.where((e) => e.completed == true), isEmpty);
      expect(await repository.isCompletedSent('l1'), isFalse);
    });
  });
}

ProgressReporter _makeReporter(ProgressRepository repository) {
  final summary = ProgressSummaryService(repository);
  addTearDown(summary.dispose);
  return ProgressReporter(repository: repository, summary: summary);
}

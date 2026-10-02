import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';

/// A server returning [summary] and [history] until it goes [offline].
class _FakeProgressRemote implements ProgressRemoteDataSource {
  ProgressSummary summary = _summary(minutes: 12);
  List<ProgressDay> history = const [
    ProgressDay(day: '2026-10-01', listenedMs: 60000, segmentRepeats: 4),
  ];
  bool offline = false;

  @override
  Future<ProgressSummary> getSummary() async {
    if (offline) throw const NetworkFailure('offline');
    return summary;
  }

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async {
    if (offline) throw const NetworkFailure('offline');
    return history;
  }

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async => summary;
}

/// Saved server responses in memory.
class _FakeProgressLocal implements ProgressLocalDataSource {
  ProgressSummary? summary;
  List<ProgressDay>? history;

  @override
  Future<ProgressSummary?> readSummary() async => summary;

  @override
  Future<void> saveSummary(ProgressSummary summary) async =>
      this.summary = summary;

  @override
  Future<List<ProgressDay>?> readHistory() async => history;

  @override
  Future<void> saveHistory(List<ProgressDay> days) async => history = days;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('$ProgressRepositoryImpl offline', () {
    test('the last summary is returned offline', () async {
      final remote = _FakeProgressRemote();
      final repository = ProgressRepositoryImpl(
        local: _FakeProgressLocal(),
        remote: remote,
      );
      await repository.getSummary();

      remote.offline = true;
      final summary = await repository.getSummary();

      expect(summary.today.listenedMinutes, equals(12));
    });

    test('a reported event refreshes the saved summary', () async {
      final remote = _FakeProgressRemote();
      final local = _FakeProgressLocal();
      final repository = ProgressRepositoryImpl(local: local, remote: remote);

      remote.summary = _summary(minutes: 20);
      await repository.reportEvents(listenedMs: 60000);

      expect(local.summary?.today.listenedMinutes, equals(20));
    });

    test('without a saved summary the network failure is thrown', () async {
      final repository = ProgressRepositoryImpl(
        local: _FakeProgressLocal(),
        remote: _FakeProgressRemote()..offline = true,
      );

      expect(repository.getSummary(), throwsA(isA<NetworkFailure>()));
    });

    test('the last history is returned offline', () async {
      final remote = _FakeProgressRemote();
      final repository = ProgressRepositoryImpl(
        local: _FakeProgressLocal(),
        remote: remote,
      );
      await repository.getHistory();

      remote.offline = true;
      final history = await repository.getHistory();

      expect(history.map((day) => day.day), equals(['2026-10-01']));
    });
  });

  group('$ProgressSummary', () {
    test('toJson is read back by fromJson', () {
      final summary = _summary(minutes: 7);

      final restored = ProgressSummary.fromJson(summary.toJson());

      expect(restored.toJson(), equals(summary.toJson()));
    });
  });
}

ProgressSummary _summary({required int minutes}) => ProgressSummary(
  today: ProgressDay(
    day: '2026-10-02',
    listenedMs: minutes * 60000,
    segmentRepeats: 3,
  ),
  totals: ProgressTotals(
    listenedMs: minutes * 60000,
    segmentRepeats: 3,
    lessonsCompleted: 1,
  ),
  weekMinutes: minutes,
  week: [
    ProgressDay(
      day: '2026-10-02',
      listenedMs: minutes * 60000,
      segmentRepeats: 3,
    ),
  ],
  recentLessonIds: const ['l1'],
  completionReps: 3,
  dailyGoalMinutes: 30,
);

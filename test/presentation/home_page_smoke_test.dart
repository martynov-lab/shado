import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/features/home/presentation/screens/home_page.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/theme/theme.dart';

import 'fake_auth_repository.dart';
import 'fake_lesson_repository.dart';

/// Progress server: the summary arrives when [summary] completes.
class _FakeProgressRemote implements ProgressRemoteDataSource {
  _FakeProgressRemote(this.summary);

  final Future<ProgressSummary> summary;

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) => summary;

  @override
  Future<ProgressSummary> getSummary() => summary;

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async => const [];
}

final _summary = ProgressSummary(
  today: const ProgressDay(
    day: '2026-08-08',
    listenedMs: 18 * 60000,
    segmentRepeats: 32,
  ),
  totals: const ProgressTotals(
    listenedMs: 126 * 60000,
    segmentRepeats: 240,
    lessonsCompleted: 3,
  ),
  weekMinutes: 126,
  week: [
    for (var i = 0; i < 7; i++)
      ProgressDay(
        day: '2026-08-0${i + 2}',
        listenedMs: (i * 5) * 60000,
        segmentRepeats: i * 4,
      ),
  ],
  recentLessonIds: const [],
  completionReps: 3,
  dailyGoalMinutes: 30,
);

void main() {
  Future<void> pumpHome(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: testUser()),
          ),
          progressRemoteDataSourceProvider.overrideWithValue(
            _FakeProgressRemote(Future.value(_summary)),
          ),
          lessonRepositoryProvider.overrideWithValue(FakeLessonRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const Scaffold(body: HomePage()),
        ),
      ),
    );
    await tester.pump();
  }

  for (final size in const [
    Size(390, 844),
    Size(640, 960),
    Size(760, 1024),
    Size(1280, 800),
  ]) {
    testWidgets('HomePage renders at $size without exceptions', (tester) async {
      await pumpHome(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}

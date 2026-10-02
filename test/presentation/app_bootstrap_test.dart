import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/app.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';

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
    segmentRepeats: 5,
  ),
  totals: const ProgressTotals(
    listenedMs: 18 * 60000,
    segmentRepeats: 5,
    lessonsCompleted: 1,
  ),
  weekMinutes: 18,
  week: const [],
  recentLessonIds: const [],
  completionReps: 3,
  dailyGoalMinutes: 30,
);

void main() {
  testWidgets('the splash holds while the progress summary loads', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final completer = Completer<ProgressSummary>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: testUser()),
          ),
          lessonRepositoryProvider.overrideWithValue(FakeLessonRepository()),
          progressRemoteDataSourceProvider.overrideWithValue(
            _FakeProgressRemote(completer.future),
          ),
        ],
        child: const ShadoApp(),
      ),
    );
    await tester.pump();

    // The summary is still in flight, so the splash shows, not the home.
    expect(find.text('Shadowing'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsNothing);

    // The summary arrived, warm-up ended and the router goes home.
    completer.complete(_summary);
    await tester.pumpAndSettle();

    expect(find.text('Shadowing'), findsNothing);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });
}

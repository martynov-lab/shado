import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/app.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/presentation/controllers/lessons_controller.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/presentation/controllers/progress_providers.dart';

/// Сессия уже поднята — интересует только прогрев после входа.
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: AuthUser(
      id: 'user-1',
      email: 'user@example.com',
      role: UserRole.user,
      createdAt: DateTime.utc(2026),
    ),
  );
}

/// Список уроков нас здесь не занимает.
class _FakeLessons extends LessonsController {
  @override
  Future<List<Lesson>> build() async => const <Lesson>[];
}

/// Сводка, приход которой контролирует тест: пока future не завершён — прогрев
/// висит в загрузке, и роутер обязан держать заставку.
class _HeldProgressSummary extends ProgressSummaryController {
  _HeldProgressSummary(this.pending);

  final Future<ProgressSummary> pending;

  @override
  Future<ProgressSummary> build() => pending;
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
  testWidgets('заставка держится, пока грузится сводка прогресса', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final completer = Completer<ProgressSummary>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          lessonsControllerProvider.overrideWith(_FakeLessons.new),
          progressSummaryProvider.overrideWith(
            () => _HeldProgressSummary(completer.future),
          ),
          progressHistoryProvider.overrideWith(
            (ref) => Future.value(const <ProgressDay>[]),
          ),
        ],
        child: const ShadoApp(),
      ),
    );
    await tester.pump();

    // Сводка ещё в пути — на экране заставка, а не главный.
    expect(find.text('Shadowing'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsNothing);

    // Сводка пришла — прогрев завершился, роутер уводит на главный.
    completer.complete(_summary);
    await tester.pumpAndSettle();

    expect(find.text('Shadowing'), findsNothing);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });
}

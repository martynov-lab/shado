import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shado/features/home/presentation/pages/home_page.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/presentation/controllers/lessons_controller.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/presentation/controllers/progress_providers.dart';
import 'package:shado/theme/theme.dart';

/// Подделка контроллера сессии: отдаёт готовое состояние и не ходит в
/// репозиторий, чтобы экран можно было отрисовать без сети и хранилища.
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

/// Подделка сводки прогресса: фиксированные метрики без похода на сервер.
class _FakeProgressSummary extends ProgressSummaryController {
  @override
  Future<ProgressSummary> build() async => _summary;
}

/// Пустой список уроков без обращения к кешу и сети.
class _FakeLessons extends LessonsController {
  @override
  Future<List<Lesson>> build() async => const <Lesson>[];
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
          authControllerProvider.overrideWith(_FakeAuthController.new),
          progressSummaryProvider.overrideWith(_FakeProgressSummary.new),
          progressHistoryProvider.overrideWith(
            (ref) => Future.value(const <ProgressDay>[]),
          ),
          lessonsControllerProvider.overrideWith(_FakeLessons.new),
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
    testWidgets('HomePage рисуется на $size без исключений', (tester) async {
      await pumpHome(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}

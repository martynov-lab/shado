import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/controllers/lessons_controller.dart';
import '../../../lessons/presentation/pages/lesson_page.dart';
import '../../../lessons/presentation/pages/lessons_page.dart';
import '../../../progress/domain/entities/progress_summary.dart';
import '../../../progress/presentation/controllers/progress_providers.dart';
import '../controllers/home_lesson_tile.dart';
import '../controllers/home_view_model.dart';
import '../widgets/home_desktop_view.dart';
import '../widgets/home_mobile_view.dart';
import '../widgets/home_tablet_view.dart';

/// Home screen: greeting, continue card, stats, weekly goal and lessons.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(
      authControllerProvider.select((state) => state.user?.email ?? ''),
    );
    final name = _greetingName(email);

    // While the summary loads, show zeros instead of a full-screen spinner.
    final summary = ref.watch(progressSummaryProvider).value;
    final history =
        ref.watch(progressHistoryProvider).value ?? const <ProgressDay>[];
    final allLessons =
        ref.watch(lessonsControllerProvider).value ?? const <Lesson>[];

    final model = HomeViewModel.from(summary, history);
    final lessons = _recentLessons(model.recentLessonIds, allLessons);

    void openLessons() => context.go(LessonsPage.routePath);
    void openLesson(String id) => context.push(LessonPage.routeTo(id));

    return AppAdaptiveLayout(
      mobile: (context) => HomeMobileView(
        name: name,
        model: model,
        lessons: lessons,
        onOpenLessons: openLessons,
        onOpenLesson: openLesson,
      ),
      tablet: (context) => HomeTabletView(
        name: name,
        model: model,
        lessons: lessons,
        lessonsCount: allLessons.length,
        onOpenLessons: openLessons,
        onOpenLesson: openLesson,
      ),
      desktop: (context) => HomeDesktopView(
        name: name,
        model: model,
        lessons: lessons,
        lessonsCount: allLessons.length,
        onOpenLessons: openLessons,
        onOpenLesson: openLesson,
      ),
    );
  }
}

/// Up to five preview lessons: recent ones, otherwise the first from the
/// catalog.
List<HomeLessonTile> _recentLessons(List<String> recentIds, List<Lesson> all) {
  final byId = {for (final lesson in all) lesson.id: lesson};
  final recent = <Lesson>[
    for (final id in recentIds) ?byId[id],
  ];
  final source = recent.isNotEmpty ? recent : all;
  return [for (final lesson in source.take(5)) HomeLessonTile.from(lesson)];
}

/// Greeting name from the email — the local part, capitalized.
String _greetingName(String email) {
  final local = email.split('@').first.trim();
  if (local.isEmpty) return 'друг';
  return local[0].toUpperCase() + local.substring(1);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson.dart';
import '../controllers/lessons_controller.dart';
import '../controllers/lessons_filter.dart';
import '../widgets/delete_lesson_dialog.dart';
import '../widgets/lessons_desktop_layout.dart';
import '../widgets/lessons_error_view.dart';
import '../widgets/lessons_mobile_layout.dart';
import '../widgets/lessons_tablet_layout.dart';
import 'lesson_page.dart';

/// Список уроков — раздел «Уроки». Данные и фильтрацию держат провайдеры,
/// раскладку выбирает [AppAdaptiveLayout]. Каркас (Scaffold, фон, навигация) —
/// у [MainShell].
class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  static const String routePath = '/lessons';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsControllerProvider);
    final controller = ref.read(lessonsControllerProvider.notifier);
    final filtered = ref.watch(filteredLessonsProvider).value ?? const <Lesson>[];

    return switch (lessons) {
      AsyncError(:final error) => LessonsErrorView(
        message: '$error',
        onRetryPressed: controller.refresh,
      ),
      AsyncData(value: final items) => AppAdaptiveLayout(
        mobile: (context) => LessonsMobileLayout(
          lessons: filtered,
          emptyLibrary: items.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) => _confirmDelete(context, controller, lesson),
          onRefresh: controller.refresh,
        ),
        tablet: (context) => LessonsTabletLayout(
          lessons: filtered,
          emptyLibrary: items.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) => _confirmDelete(context, controller, lesson),
          onRefresh: controller.refresh,
        ),
        desktop: (context) => LessonsDesktopLayout(
          lessons: filtered,
          emptyLibrary: items.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) => _confirmDelete(context, controller, lesson),
          onRefresh: controller.refresh,
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  void _open(BuildContext context, Lesson lesson) =>
      context.push(LessonPage.routeTo(lesson.id));

  Future<void> _confirmDelete(
    BuildContext context,
    LessonsController controller,
    Lesson lesson,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteLessonDialog(lessonTitle: lesson.title),
    );
    if (confirmed != true) return;
    await controller.delete(lesson.id);
  }
}

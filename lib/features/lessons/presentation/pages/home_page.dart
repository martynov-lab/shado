import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/lesson.dart';
import '../controllers/lessons_controller.dart';
import '../widgets/account_menu.dart';
import '../widgets/delete_lesson_dialog.dart';
import '../widgets/empty_lessons_view.dart';
import '../widgets/lesson_card.dart';
import '../widgets/lessons_error_view.dart';
import 'lesson_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsControllerProvider);
    final controller = ref.read(lessonsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: const [AccountMenu()],
      ),
      body: switch (lessons) {
        AsyncError(:final error) => LessonsErrorView(
          message: '$error',
          onRetryPressed: controller.refresh,
        ),
        AsyncData(value: final items) when items.isEmpty =>
          const EmptyLessonsView(),
        AsyncData(value: final items) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) => LessonCard(
              lesson: items[index],
              onTap: () => context.push(LessonPage.routeTo(items[index].id)),
              onDelete: () => _confirmDelete(context, controller, items[index]),
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

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

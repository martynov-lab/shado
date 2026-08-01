import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/lesson.dart';
import 'lesson_grid_card.dart';

/// Сетка карточек уроков с pull-to-refresh (планшет).
class LessonsGridView extends StatelessWidget {
  const LessonsGridView({
    super.key,
    required this.lessons,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<Lesson> lessons;
  final void Function(Lesson) onOpen;
  final void Function(Lesson) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.s4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.s4,
          mainAxisSpacing: AppSpacing.s4,
          mainAxisExtent: 200,
        ),
        itemCount: lessons.length,
        itemBuilder: (context, index) => LessonGridCard(
          lesson: lessons[index],
          onTap: () => onOpen(lessons[index]),
          onDelete: () => onDelete(lessons[index]),
        ),
      ),
    );
  }
}

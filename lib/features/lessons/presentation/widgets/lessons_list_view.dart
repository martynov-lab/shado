import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/lesson.dart';
import 'lesson_list_row.dart';
import 'lesson_row_divider.dart';

/// Прокручиваемый список строк уроков с pull-to-refresh. Общий для телефона и
/// десктопа.
class LessonsListView extends StatelessWidget {
  const LessonsListView({
    super.key,
    required this.lessons,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.s4),
  });

  final List<Lesson> lessons;
  final void Function(Lesson) onOpen;
  final void Function(Lesson) onDelete;
  final Future<void> Function() onRefresh;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: padding,
        itemCount: lessons.length,
        separatorBuilder: (_, _) => const LessonRowDivider(),
        itemBuilder: (context, index) => LessonListRow(
          lesson: lessons[index],
          onTap: () => onOpen(lessons[index]),
          onDelete: () => onDelete(lessons[index]),
        ),
      ),
    );
  }
}

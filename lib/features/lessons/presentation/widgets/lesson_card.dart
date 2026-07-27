import 'package:flutter/material.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/lesson.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    required this.onDelete,
  });

  final Lesson lesson;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: ValueKey('lesson-${lesson.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          // Удалением управляет страница: карточка исчезнет вместе с данными.
          return false;
        },
        background: ColoredBox(
          color: theme.colorScheme.errorContainer,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(lesson.title, style: theme.textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_segmentsLabel(lesson.segmentCount)} · '
              '${formatPosition(lesson.durationMs)} · '
              '${formatDate(lesson.createdAt)}',
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          onLongPress: onDelete,
        ),
      ),
    );
  }

  String _segmentsLabel(int count) {
    final lastTwo = count % 100;
    final last = count % 10;
    if (lastTwo >= 11 && lastTwo <= 14) return '$count кусков';
    if (last == 1) return '$count кусок';
    if (last >= 2 && last <= 4) return '$count куска';
    return '$count кусков';
  }
}

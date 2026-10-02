import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/lessons_filter.dart';
import '../screens/lessons/lesson_filter_group.dart';
import 'lessons_filter_clear_button.dart';
import 'lessons_filter_trigger.dart';

/// Row of filter chips; each opens a sheet with its group checkboxes.
class LessonsFilterBar extends StatelessWidget {
  const LessonsFilterBar({
    super.key,
    required this.filter,
    required this.groups,
    required this.onOpenGroup,
    required this.onClear,
  });

  final LessonsFilter filter;
  final List<LessonFilterGroup> groups;
  final ValueChanged<LessonFilterGroup> onOpenGroup;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final group in groups) ...[
            LessonsFilterTrigger(
              label: group.title,
              count: group.countIn(filter),
              onTap: () => onOpenGroup(group),
            ),
            const SizedBox(width: AppSpacing.s2),
          ],
          if (filter.activeCount > 0)
            LessonsFilterClearButton(onTap: onClear),
        ],
      ),
    );
  }
}

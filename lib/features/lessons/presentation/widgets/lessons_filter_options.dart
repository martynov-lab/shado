import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';

import '../../../languages/domain/entities/language.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/lessons_filter.dart';
import '../screens/lessons/lesson_filter_group.dart';
import 'lessons_filter_group_options.dart';
import 'lessons_filter_group_section.dart';

/// Every filter group, each one collapsible.
class LessonsFilterOptions extends StatelessWidget {
  const LessonsFilterOptions({
    super.key,
    required this.groups,
    required this.filter,
    required this.topics,
    required this.accents,
    required this.onChanged,
  });

  final List<LessonFilterGroup> groups;
  final LessonsFilter filter;
  final AsyncState<List<Topic>> topics;
  final List<Accent> accents;
  final ValueChanged<LessonsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final group in groups)
          LessonsFilterGroupSection(
            title: group.title,
            child: LessonsFilterGroupOptions(
              group: group,
              filter: filter,
              topics: topics,
              accents: accents,
              onChanged: onChanged,
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';

import '../../../languages/domain/entities/language.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/lessons_filter.dart';
import '../screens/lessons/lesson_filter_group.dart';
import 'lessons_filter_option_row.dart';

/// Checkboxes of one filter group.
class LessonsFilterGroupOptions extends StatelessWidget {
  const LessonsFilterGroupOptions({
    super.key,
    required this.group,
    required this.filter,
    required this.topics,
    required this.accents,
    required this.onChanged,
  });

  final LessonFilterGroup group;
  final LessonsFilter filter;
  final AsyncState<List<Topic>> topics;

  /// Accents of the studied language.
  final List<Accent> accents;

  final ValueChanged<LessonsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (group) {
      LessonFilterGroup.topic => switch (topics) {
        AsyncReady(:final value) when value.isNotEmpty => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final topic in value)
              LessonsFilterOptionRow(
                label: topic.name,
                selected: filter.topicIds.contains(topic.id),
                onToggle: () => onChanged(filter.toggleTopic(topic.id)),
              ),
          ],
        ),
        AsyncFailed() => Text(
          'Topics unavailable',
          style: AppText.caption.copyWith(color: context.colors.text3),
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox.square(
              dimension: AppSizes.iconMd,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      },
      LessonFilterGroup.level => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final level in LessonLevel.values)
            LessonsFilterOptionRow(
              label: level.label,
              selected: filter.levels.contains(level),
              onToggle: () => onChanged(filter.toggleLevel(level)),
            ),
        ],
      ),
      LessonFilterGroup.accent => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final accent in accents)
            LessonsFilterOptionRow(
              label: accent.label,
              selected: filter.accents.contains(accent.code),
              onToggle: () => onChanged(filter.toggleAccent(accent.code)),
            ),
        ],
      ),
      LessonFilterGroup.status => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final status in LessonFilterStatus.values)
            LessonsFilterOptionRow(
              label: status.label,
              selected: filter.statuses.contains(status),
              onToggle: () => onChanged(filter.toggleStatus(status)),
            ),
        ],
      ),
      // The server returns only the viewer's own private lessons.
      LessonFilterGroup.access => LessonsFilterOptionRow(
        label: 'My private',
        selected: filter.onlyPrivate,
        onToggle: () => onChanged(filter.toggleOnlyPrivate()),
      ),
    };
  }
}

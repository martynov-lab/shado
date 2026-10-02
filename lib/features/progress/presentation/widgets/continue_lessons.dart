import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../../lessons/domain/entities/lesson.dart';
import 'continue_lesson_card.dart';

/// Continue block with recent lessons; hidden when there are none.
class ContinueLessons extends StatelessWidget {
  const ContinueLessons({
    super.key,
    required this.lessons,
    required this.onOpenLesson,
  });

  final List<Lesson> lessons;
  final ValueChanged<Lesson> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Continue', style: AppText.title.copyWith(color: colors.text)),
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lessons.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
            itemBuilder: (context, index) => ContinueLessonCard(
              lesson: lessons[index],
              onTap: () => onOpenLesson(lessons[index]),
            ),
          ),
        ),
      ],
    );
  }
}

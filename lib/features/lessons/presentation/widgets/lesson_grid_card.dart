import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/lessons_filter.dart';
import 'lesson_gradients.dart';
import 'lesson_labels.dart';
import 'lesson_play_bubble.dart';
import 'lesson_progress_bar.dart';

/// Lesson grid card: a cap with a play button, the title and progress.
class LessonGridCard extends StatelessWidget {
  const LessonGridCard({
    super.key,
    required this.lesson,
    required this.progress,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final Lesson lesson;

  /// How much of the lesson is done, `0..1`.
  final double progress;

  /// Long press deletes only for users allowed to.
  final bool canDelete;

  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onLongPress: canDelete ? onDelete : null,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        semanticLabel: lesson.title,
        child: ClipRRect(
          borderRadius: AppRadii.rXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 88,
                decoration: BoxDecoration(
                  gradient: lessonBrandGradient(colors),
                ),
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: AppSpacing.s2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (lesson.isPrivate)
                              // The privacy padlock is light on the gradient.
                              AppIcon(
                                AppIcons.lock,
                                size: AppSizes.iconSm,
                                color: colors.primaryOn,
                                semanticLabel: 'Private',
                              ),
                            if (lessonIsNew(lesson))
                              const AppBadge(label: 'New'),
                          ],
                        ),
                        const LessonPlayBubble(),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lesson.title,
                      style: AppText.title.copyWith(color: colors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      lessonSubtitle(lesson),
                      style: AppText.caption.copyWith(color: colors.text2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    LessonProgressBar(value: progress),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

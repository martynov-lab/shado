import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson.dart';
import '../controllers/lessons_filter.dart';
import 'lesson_gradients.dart';
import 'lesson_labels.dart';
import 'lesson_progress_bar.dart';

/// Карточка урока для сетки на планшете: градиентная «крышка» с меткой и
/// кнопкой play, ниже — заголовок, подзаголовок и прогресс.
class LessonGridCard extends StatelessWidget {
  const LessonGridCard({
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
    final colors = context.colors;

    return GestureDetector(
      onLongPress: onDelete,
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
                        if (lessonIsNew(lesson))
                          const AppBadge(label: 'New')
                        else
                          const SizedBox.shrink(),
                        _PlayBubble(),
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
                    const LessonProgressBar(),
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

/// Белый кружок с play в углу «крышки» карточки.
class _PlayBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AppIcon(AppIcons.play, size: AppSizes.iconSm, color: colors.primary),
      ),
    );
  }
}

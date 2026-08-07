import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../progress/presentation/controllers/progress_providers.dart';
import '../../domain/entities/lesson.dart';
import '../controllers/lesson_permissions.dart';
import '../controllers/lessons_filter.dart';
import 'lesson_gradients.dart';
import 'lesson_labels.dart';
import 'lesson_progress_bar.dart';

/// Карточка урока для сетки на планшете: градиентная «крышка» с меткой и
/// кнопкой play, ниже — заголовок, подзаголовок и прогресс.
class LessonGridCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final role = ref.watch(
      authControllerProvider.select((auth) => auth.user?.role),
    );
    // Удаление долгим нажатием — только тому, кто вправе; иначе жест не вешаем.
    final canDelete = canModifyLesson(role, lesson);
    final progress =
        ref
            .watch(
              lessonProgressProvider((
                lessonId: lesson.id,
                segmentCount: lesson.segmentCount,
              )),
            )
            .value ??
        0.0;

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
                          children: [
                            if (lesson.isPrivate)
                              const AppBadge(
                                label: 'Приватный',
                                variant: AppBadgeVariant.neutral,
                              ),
                            if (lessonIsNew(lesson))
                              const AppBadge(label: 'New'),
                          ],
                        ),
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

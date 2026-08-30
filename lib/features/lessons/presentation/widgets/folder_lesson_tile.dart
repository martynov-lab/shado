import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_cover.dart';
import 'lesson_labels.dart';

/// Строка урока внутри папки: обложка, заголовок, подзаголовок и — у автора —
/// кнопка «убрать из папки». Тап открывает урок.
///
/// Отдельная от [LessonListRow] строка: там свайп удаляет урок навсегда, а
/// здесь речь только о снятии группировки, не о судьбе урока.
class FolderLessonTile extends StatelessWidget {
  const FolderLessonTile({
    super.key,
    required this.lesson,
    required this.onOpen,
    this.onRemove,
  });

  final Lesson lesson;
  final VoidCallback onOpen;

  /// Убрать урок из папки. `null` — у зрителя без прав автора кнопки нет.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: lesson.title,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onOpen,
          borderRadius: AppRadii.rLg,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                const LessonCover(size: 56),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson.title,
                              style: AppText.title.copyWith(color: colors.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lesson.isPrivate) ...[
                            const SizedBox(width: AppSpacing.s2),
                            AppIcon(
                              AppIcons.lock,
                              size: AppSizes.iconSm,
                              color: colors.text2,
                              semanticLabel: 'Приватный',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        lessonSubtitle(lesson),
                        style: AppText.caption.copyWith(color: colors.text2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  formatClock(lesson.trim.durationMs),
                  style: AppText.monoTime.copyWith(color: colors.text2),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: AppSpacing.s1),
                  AppIconButton(
                    icon: Icons.close,
                    semanticLabel: 'Убрать из папки',
                    size: AppButtonSize.sm,
                    onPressed: onRemove,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

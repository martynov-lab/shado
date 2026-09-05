import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_cover.dart';
import 'lesson_labels.dart';

/// Lesson row inside a folder with a remove-from-folder button.
class FolderLessonTile extends StatelessWidget {
  const FolderLessonTile({
    super.key,
    required this.lesson,
    required this.onOpen,
    this.onRemove,
  });

  final Lesson lesson;
  final VoidCallback onOpen;

  /// Removes a lesson from the folder; `null` hides the button.
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

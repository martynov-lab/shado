import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_download.dart';
import '../../domain/entities/lessons_filter.dart';
import 'lesson_cover.dart';
import 'lesson_download_button.dart';
import 'lesson_labels.dart';
import 'lesson_progress_bar.dart';

/// Lesson list row; a swipe or a long press deletes the lesson.
class LessonListRow extends StatefulWidget {
  const LessonListRow({
    super.key,
    required this.lesson,
    required this.progress,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
    required this.download,
    required this.onToggleDownload,
    this.isAvailable = true,
  });

  final Lesson lesson;

  /// How much of the lesson is done, `0..1`.
  final double progress;

  /// Swipe and long press delete only for users allowed to.
  final bool canDelete;

  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Offline availability shown by the download button.
  final LessonDownload download;

  /// `null` disables the download button.
  final VoidCallback? onToggleDownload;

  /// Dims a lesson that can't be opened offline.
  final bool isAvailable;

  @override
  State<LessonListRow> createState() => _LessonListRowState();
}

class _LessonListRowState extends State<LessonListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = widget.lesson;
    final canDelete = widget.canDelete;
    final progress = widget.progress;

    return Dismissible(
      key: ValueKey('lesson-${lesson.id}'),
      direction: canDelete
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        widget.onDelete();
        // The page drives deletion: the row disappears with the data.
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.s5),
        decoration: BoxDecoration(
          color: colors.dangerSoft,
          borderRadius: AppRadii.rLg,
        ),
        child: AppIcon(
          AppIcons.trash,
          size: AppSizes.iconMd,
          color: colors.danger,
        ),
      ),
      child: Semantics(
        button: true,
        label: lesson.title,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: canDelete ? widget.onDelete : null,
            onHover: (value) => setState(() => _hovered = value),
            borderRadius: AppRadii.rLg,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: AnimatedOpacity(
              opacity: widget.isAvailable ? 1 : 0.5,
              duration: context.motion(AppDurations.fast),
              child: AnimatedContainer(
                duration: context.motion(AppDurations.fast),
                curve: AppCurves.standard,
                padding: const EdgeInsets.all(AppSpacing.s3),
                decoration: BoxDecoration(
                  color: _hovered ? colors.surface2 : Colors.transparent,
                  borderRadius: AppRadii.rLg,
                ),
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
                              // The title pushes the badges to the right edge.
                              Expanded(
                                child: Text(
                                  lesson.title,
                                  style: AppText.title.copyWith(
                                    color: colors.text,
                                  ),
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
                                  semanticLabel: 'Private',
                                ),
                              ],
                              if (lessonIsNew(lesson)) ...[
                                const SizedBox(width: AppSpacing.s2),
                                const AppBadge(label: 'New'),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            lessonSubtitle(lesson),
                            style: AppText.caption.copyWith(
                              color: colors.text2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          // Duration sits right of the progress bar.
                          Row(
                            children: [
                              Expanded(
                                child: LessonProgressBar(value: progress),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Text(
                                formatClock(lesson.trim.durationMs),
                                style: AppText.monoTime.copyWith(
                                  color: colors.text2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    LessonDownloadButton(
                      download: widget.download,
                      onPressed: widget.onToggleDownload,
                      size: AppButtonSize.sm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

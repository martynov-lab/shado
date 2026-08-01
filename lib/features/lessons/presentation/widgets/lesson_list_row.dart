import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/lesson.dart';
import '../controllers/lessons_filter.dart';
import 'lesson_cover.dart';
import 'lesson_labels.dart';
import 'lesson_progress_bar.dart';

/// Строка списка уроков: обложка, заголовок с меткой «New», подзаголовок,
/// полоса прогресса и длительность. Свайп влево или долгое нажатие — удаление.
class LessonListRow extends StatefulWidget {
  const LessonListRow({
    super.key,
    required this.lesson,
    required this.onTap,
    required this.onDelete,
  });

  final Lesson lesson;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<LessonListRow> createState() => _LessonListRowState();
}

class _LessonListRowState extends State<LessonListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = widget.lesson;

    return Dismissible(
      key: ValueKey('lesson-${lesson.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete();
        // Удалением управляет страница: строка исчезнет вместе с данными.
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
            onLongPress: widget.onDelete,
            onHover: (value) => setState(() => _hovered = value),
            borderRadius: AppRadii.rLg,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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
                            Flexible(
                              child: Text(
                                lesson.title,
                                style: AppText.title.copyWith(color: colors.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (lessonIsNew(lesson)) ...[
                              const SizedBox(width: AppSpacing.s2),
                              const AppBadge(label: 'New'),
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
                        const SizedBox(height: AppSpacing.s2),
                        const LessonProgressBar(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Text(
                    formatPosition(lesson.trim.durationMs),
                    style: AppText.monoTime.copyWith(color: colors.text2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

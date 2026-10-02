import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../screens/lesson/lesson_state.dart';
import 'lesson_labels.dart';
import 'lesson_segment_row.dart';
import 'lesson_segments_tool_link.dart';

/// Segment list panel; [shrinkWrap] fits it into a modal sheet.
class LessonSegmentsPanel extends StatelessWidget {
  const LessonSegmentsPanel({
    super.key,
    required this.state,
    required this.onSegmentPressed,
    required this.onSelectPressed,
    required this.onStartSelecting,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onDone,
    required this.onToggleLoop,
    this.shrinkWrap = false,
  });

  final LessonState state;
  final ValueChanged<int> onSegmentPressed;

  /// A tap on a segment in selection mode.
  final ValueChanged<int> onSelectPressed;

  final VoidCallback onStartSelecting;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  /// Leaves selection mode keeping the picked range.
  final VoidCallback onDone;

  final VoidCallback onToggleLoop;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final segments = state.lesson.segments;

    final list = ListView.builder(
      shrinkWrap: shrinkWrap,
      primary: false,
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      itemCount: segments.length,
      itemBuilder: (context, index) => LessonSegmentRow(
        segment: segments[index],
        isCurrent: state.currentIndex == index,
        isPlaying: state.isSegmentPlaying(index),
        isSelecting: state.isSelecting,
        isSelected: state.isSegmentSelected(index),
        onPressed: () => onSegmentPressed(index),
        onSelectPressed: () => onSelectPressed(index),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Segments · ${state.currentIndex + 1}/${segments.length}',
                style: AppText.title.copyWith(color: colors.text),
              ),
            ),
            if (state.isSelecting) ...[
              LessonSegmentsToolLink(
                label: state.selection == null ? 'Select all' : 'Clear',
                onTap: state.selection == null
                    ? onSelectAll
                    : onClearSelection,
              ),
              const SizedBox(width: AppSpacing.s4),
              LessonSegmentsToolLink(
                label: 'Done',
                onTap: onDone,
              ),
            ] else
              LessonSegmentsToolLink(
                label: 'Select several',
                onTap: onStartSelecting,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        if (shrinkWrap) Flexible(child: list) else Expanded(child: list),
        if (state.selection case final selection? when state.isSelecting) ...[
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${segmentsLabel(selection.length)} · '
                  '${formatPosition(state.selectionDurationMs)}',
                  style: AppText.caption.copyWith(color: colors.text2),
                ),
              ),
              AppIconButton(
                icon: Icons.repeat_rounded,
                semanticLabel: state.isLooped
                    ? 'Turn off repeat of selection'
                    : 'Repeat selection',
                variant: state.isLooped
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: onToggleLoop,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

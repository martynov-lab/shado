import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/segment.dart';
import 'lesson_labels.dart';

/// Segment row: number, text and duration; a tap loads or selects it.
class LessonSegmentRow extends StatefulWidget {
  const LessonSegmentRow({
    super.key,
    required this.segment,
    required this.isCurrent,
    required this.isPlaying,
    required this.isSelecting,
    required this.isSelected,
    required this.onPressed,
    required this.onSelectPressed,
  });

  final Segment segment;

  /// The segment is loaded into the player — highlight the row.
  final bool isCurrent;
  final bool isPlaying;

  final bool isSelecting;
  final bool isSelected;

  final VoidCallback onPressed;
  final VoidCallback onSelectPressed;

  @override
  State<LessonSegmentRow> createState() => _LessonSegmentRowState();
}

class _LessonSegmentRowState extends State<LessonSegmentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highlighted =
        widget.isSelected || (widget.isCurrent && !widget.isSelecting);

    final background = highlighted
        ? colors.primarySoft
        : (_hovered ? colors.surface2 : Colors.transparent);

    return Semantics(
      button: true,
      selected: widget.isSelecting ? widget.isSelected : widget.isCurrent,
      label: widget.segment.text,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.isSelecting ? widget.onSelectPressed : widget.onPressed,
          onHover: (value) => setState(() => _hovered = value),
          borderRadius: AppRadii.rMd,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedContainer(
            duration: context.motion(AppDurations.fast),
            curve: AppCurves.standard,
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadii.rMd,
            ),
            child: Row(
              children: [
                if (widget.isSelecting) ...[
                  AppCheckbox(
                    value: widget.isSelected,
                    onChanged: (_) => widget.onSelectPressed(),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                ],
                SizedBox(
                  width: AppSpacing.s6,
                  child: Text(
                    segmentNumber(widget.segment.index),
                    textAlign: TextAlign.center,
                    style: AppText.monoTime.copyWith(
                      color: widget.isCurrent ? colors.primary : colors.text3,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.segment.text,
                        style: AppText.label.copyWith(color: colors.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        segmentTimecodes(widget.segment),
                        style: AppText.caption.copyWith(color: colors.text3),
                      ),
                    ],
                  ),
                ),
                if (widget.isPlaying) ...[
                  const SizedBox(width: AppSpacing.s2),
                  AppIcon(
                    AppIcons.pause,
                    size: AppSizes.iconSm,
                    color: colors.primary,
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

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'lesson_labels.dart';

/// A phrase in the list: number, text and rating; in selection mode with a
/// checkbox.
class PhraseSelectRow extends StatelessWidget {
  const PhraseSelectRow({
    super.key,
    required this.index,
    required this.text,
    required this.stars,
    required this.isCurrent,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final String text;
  final int stars;

  /// The phrase is on the card now.
  final bool isCurrent;

  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highlighted = isSelecting ? isSelected : isCurrent;

    return Semantics(
      button: true,
      selected: highlighted,
      label: text,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rMd,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: highlighted ? colors.primarySoft : Colors.transparent,
              borderRadius: AppRadii.rMd,
            ),
            child: Row(
              children: [
                if (isSelecting) ...[
                  AppCheckbox(value: isSelected, onChanged: (_) => onTap()),
                  const SizedBox(width: AppSpacing.s3),
                ],
                SizedBox(
                  width: AppSpacing.s6,
                  child: Text(
                    segmentNumber(index),
                    textAlign: TextAlign.center,
                    style: AppText.monoTime.copyWith(color: colors.text3),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    text,
                    style: AppText.label.copyWith(color: colors.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                AppStarRating(value: stars, size: AppSizes.iconSm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

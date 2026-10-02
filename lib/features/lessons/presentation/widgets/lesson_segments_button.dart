import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Opens the segment list on phones; shows which segment is current.
class LessonSegmentsButton extends StatelessWidget {
  const LessonSegmentsButton({
    super.key,
    required this.currentIndex,
    required this.count,
    required this.onTap,
  });

  final int currentIndex;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: 'Segment list',
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.rMd,
          side: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              children: [
                AppIcon(
                  AppIcons.listBullets,
                  size: AppSizes.iconMd,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  'Segment list',
                  style: AppText.title.copyWith(color: colors.text),
                ),
                const Spacer(),
                Text(
                  '${currentIndex + 1} / $count',
                  style: AppText.monoTime.copyWith(color: colors.text3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Streak chip: a flame icon and the number of days in a row.
class HomeStreakChip extends StatelessWidget {
  const HomeStreakChip({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: colors.border, width: AppSizes.borderThin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.flame, size: AppSizes.iconSm, color: colors.warning),
          const SizedBox(width: AppSpacing.s2),
          Text('$days days', style: AppText.label.copyWith(color: colors.text)),
        ],
      ),
    );
  }
}

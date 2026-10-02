import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Number of selected values on a filter chip.
class LessonsFilterCountBadge extends StatelessWidget {
  const LessonsFilterCountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        '$count',
        style: AppText.caption.copyWith(color: colors.primaryOn),
      ),
    );
  }
}

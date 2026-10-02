import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Shared chip frame: a soft surface with a dashed-looking outline.
class LessonFileChipShell extends StatelessWidget {
  const LessonFileChipShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: colors.borderStrong,
          width: AppSizes.borderThin,
        ),
      ),
      child: child,
    );
  }
}

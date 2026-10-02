import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Resets the selected filters.
class LessonsFilterClearButton extends StatelessWidget {
  const LessonsFilterClearButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      child: AppTapTarget(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.rPill,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Text(
                'Reset',
                style: AppText.label.copyWith(color: colors.text3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

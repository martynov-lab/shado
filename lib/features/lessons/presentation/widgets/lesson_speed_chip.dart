import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Current speed on the player; a tap opens the speed list.
class LessonSpeedChip extends StatelessWidget {
  const LessonSpeedChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Speed $label',
      excludeSemantics: true,
      child: Material(
        color: foreground.withValues(alpha: 0.08),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: Text(
              label,
              style: AppText.monoTime.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

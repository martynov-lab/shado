import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// A small outlined label on the player panel.
class LessonPlayerTag extends StatelessWidget {
  const LessonPlayerTag({
    super.key,
    required this.label,
    required this.foreground,
  });

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.14),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: foreground, letterSpacing: 0.6),
      ),
    );
  }
}

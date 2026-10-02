import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// A text action above the segment list.
class LessonSegmentsToolLink extends StatelessWidget {
  const LessonSegmentsToolLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rSm,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s1),
          child: Text(
            label,
            style: AppText.label.copyWith(color: context.colors.primary),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Thin divider between lesson rows, inset from the cover edges.
class LessonRowDivider extends StatelessWidget {
  const LessonRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
      child: Container(height: 1, color: context.colors.border),
    );
  }
}

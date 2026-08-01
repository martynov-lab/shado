import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Тонкая линия между строками уроков, с отступом от краёв обложки.
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

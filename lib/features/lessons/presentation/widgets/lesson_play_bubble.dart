import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// White play dot in the corner of the card cap.
class LessonPlayBubble extends StatelessWidget {
  const LessonPlayBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
      child: Center(
        child: AppIcon(
          AppIcons.play,
          size: AppSizes.iconSm,
          color: colors.primary,
        ),
      ),
    );
  }
}

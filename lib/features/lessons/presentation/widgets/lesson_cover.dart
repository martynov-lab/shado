import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'lesson_gradients.dart';

/// Квадратная обложка урока: брендовый градиент и иконка по центру.
class LessonCover extends StatelessWidget {
  const LessonCover({
    super.key,
    this.size = AppSizes.cover,
    this.icon = AppIcons.play,
    this.borderRadius = AppRadii.rMd,
  });

  final double size;
  final AppIcons icon;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: lessonBrandGradient(colors),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: AppIcon(icon, size: size * 0.4, color: colors.primaryOn),
      ),
    );
  }
}

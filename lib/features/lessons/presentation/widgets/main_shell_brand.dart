import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'lesson_gradients.dart';

/// Логотип Shadowing для навигации: градиентный квадрат с иконкой волны и,
/// по желанию, названием рядом.
class MainShellBrand extends StatelessWidget {
  const MainShellBrand({super.key, this.showLabel = false, this.size = 40});

  /// Показать название «Shadowing» с подписью справа от значка (sidebar).
  final bool showLabel;

  /// Сторона градиентного квадрата.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: lessonBrandGradient(colors),
        borderRadius: AppRadii.rMd,
        boxShadow: context.shadows.e1,
      ),
      child: Center(
        child: AppIcon(
          AppIcons.logoWave,
          size: size * 0.5,
          color: colors.primaryOn,
        ),
      ),
    );

    if (!showLabel) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: AppSpacing.s3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Shadowing', style: AppText.title.copyWith(color: colors.text)),
            Text(
              'Learn by repeating',
              style: AppText.caption.copyWith(color: colors.text3),
            ),
          ],
        ),
      ],
    );
  }
}

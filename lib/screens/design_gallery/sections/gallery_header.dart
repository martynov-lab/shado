import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Шапка витрины: название, подзаголовок и переключатель темы.
class GalleryHeader extends StatelessWidget {
  const GalleryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дизайн-система',
          style: AppText.displayLg.copyWith(color: c.text),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'Слушай. Повторяй. Все компоненты — на токенах.',
          style: AppText.body.copyWith(color: c.text2),
        ),
        const SizedBox(height: AppSpacing.s6),
        Align(
          alignment: Alignment.centerLeft,
          child: ThemeToggle(expand: context.isMobile),
        ),
      ],
    );
  }
}

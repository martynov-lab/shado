import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Lesson list placeholder shown when there are no lessons yet.
class EmptyLessonsView extends StatelessWidget {
  const EmptyLessonsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              AppIcons.headphones,
              size: AppSizes.iconLg,
              color: colors.text3,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Уроков пока нет',
              style: AppText.title.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Загрузите аудио и разметьте текст, чтобы начать заниматься.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: colors.text2),
            ),
          ],
        ),
      ),
    );
  }
}

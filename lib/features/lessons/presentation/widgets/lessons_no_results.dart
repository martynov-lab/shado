import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../controllers/lessons_filter.dart';

/// Показывается, когда под поиск и фильтры не подошёл ни один урок.
class LessonsNoResults extends ConsumerWidget {
  const LessonsNoResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.search, size: AppSizes.iconLg, color: colors.text3),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Ничего не найдено',
              style: AppText.title.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Измените запрос или сбросьте фильтры.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: colors.text2),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Сбросить фильтры',
              variant: AppButtonVariant.secondary,
              onPressed: ref.read(lessonsFilterProvider.notifier).clearFilters,
            ),
          ],
        ),
      ),
    );
  }
}

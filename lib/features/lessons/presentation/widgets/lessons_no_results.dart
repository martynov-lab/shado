import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';


/// Shown when no lesson matches the search and filters.
class LessonsNoResults extends StatelessWidget {
  const LessonsNoResults({super.key, required this.onResetFilters});

  final VoidCallback onResetFilters;

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
              AppIcons.search,
              size: AppSizes.iconLg,
              color: colors.text3,
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Nothing found',
              style: AppText.title.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Change the query or reset the filters.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: colors.text2),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Reset filters',
              variant: AppButtonVariant.secondary,
              onPressed: onResetFilters,
            ),
          ],
        ),
      ),
    );
  }
}

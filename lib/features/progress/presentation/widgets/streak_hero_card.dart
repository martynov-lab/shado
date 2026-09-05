import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Streak hero: a gradient card with a flame icon, the day count and a
/// caption below.
class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({
    super.key,
    required this.days,
    required this.hint,
  });

  final int days;

  /// Caption under the number, e.g. the best streak.
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onGrad = colors.primaryOn;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: BoxDecoration(
        gradient: AppBrand.signGradient,
        borderRadius: AppRadii.rXl,
        boxShadow: context.shadows.e2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.flame, size: AppSizes.iconLg + 10, color: onGrad),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$days',
                        style: AppText.displayLg.copyWith(color: onGrad),
                      ),
                      TextSpan(
                        text: ' дней подряд',
                        style: AppText.title.copyWith(
                          color: onGrad.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            hint,
            style: AppText.label.copyWith(
              color: onGrad.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

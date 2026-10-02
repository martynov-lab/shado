import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Heatmap cell with the minute count inside.
class ActivityHeatmapCell extends StatelessWidget {
  const ActivityHeatmapCell({
    super.key,
    required this.minutes,
    required this.colors,
  });

  static const double radius = 3;

  /// Cell opacity for the minute count.
  static double alphaFor(int minutes) {
    if (minutes <= 0) return 0.08;
    if (minutes <= 8) return 0.30;
    if (minutes <= 18) return 0.55;
    if (minutes <= 30) return 0.78;
    return 1;
  }

  final int minutes;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final alpha = alphaFor(minutes);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: minutes <= 0
          ? null
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s1),
                child: FittedBox(
                  child: Text(
                    '$minutes',
                    style: AppText.caption.copyWith(
                      color: alpha >= 0.78 ? colors.primaryOn : colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

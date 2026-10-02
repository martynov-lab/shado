import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'activity_heatmap_cell.dart';

/// Opacity scale under the heatmap, from less to more.
class ActivityHeatmapLegend extends StatelessWidget {
  const ActivityHeatmapLegend({super.key, required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final captionStyle = AppText.caption.copyWith(color: colors.text3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('less', style: captionStyle),
        const SizedBox(width: AppSpacing.s2),
        for (final alpha in const [0.30, 0.55, 0.78, 1.0])
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s1),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(ActivityHeatmapCell.radius),
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.s1),
        Text('more', style: captionStyle),
      ],
    );
  }
}

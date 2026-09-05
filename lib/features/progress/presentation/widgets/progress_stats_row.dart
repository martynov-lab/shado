import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'progress_stat.dart';

/// Row of stat tiles; each record holds a label, value, optional unit and a
/// delta. Tiles split the width evenly.
class ProgressStatsRow extends StatelessWidget {
  const ProgressStatsRow({super.key, required this.stats});

  final List<(String, String, String?, String)> stats;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight aligns the tiles to the tallest one.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: ProgressStat(
                caption: stats[i].$1,
                value: stats[i].$2,
                unit: stats[i].$3,
                delta: stats[i].$4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'home_stat.dart';

/// Row of stat tiles; with [scrollable] the tiles scroll sideways.
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.stats,
    this.scrollable = false,
  });

  final List<(String, String, String?, String)> stats;
  final bool scrollable;

  /// Tile width in the scrollable mode.
  static const double _tileWidth = 150;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final (caption, value, unit, delta) in stats)
        HomeStat(caption: caption, value: value, unit: unit, delta: delta),
    ];

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s3),
                SizedBox(width: _tileWidth, child: tiles[i]),
              ],
            ],
          ),
        ),
      );
    }

    // IntrinsicHeight aligns the tiles to the tallest one.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s3),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'activity_heatmap_cell.dart';
import 'activity_heatmap_legend.dart';

/// Activity heatmap: seven weekday rows across [columns] weeks.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.cells, this.columns = 10});

  final List<int> cells;
  final int columns;

  static const int _rows = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < _rows; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r == _rows - 1 ? 0 : AppSpacing.s1),
            child: Row(
              children: [
                for (var c = 0; c < columns; c++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: c == columns - 1 ? 0 : AppSpacing.s1,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ActivityHeatmapCell(
                          minutes: _valueAt(r, c),
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s3),
        ActivityHeatmapLegend(colors: colors),
      ],
    );
  }

  int _valueAt(int row, int col) {
    final index = row * columns + col;
    return index < cells.length ? cells[index] : 0;
  }
}

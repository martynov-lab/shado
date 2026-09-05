import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Daily minutes bar chart: heights from [values], labels from [labels].
class MinutesBarChart extends StatelessWidget {
  const MinutesBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.todayIndex,
  });

  final List<int> values;
  final List<String> labels;
  final int todayIndex;

  /// Height of the bars area.
  static const double _trackHeight = 120;
  static const double _barWidth = 24;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: _Bar(
              heightPercent: values[i],
              label: labels[i],
              isToday: i == todayIndex,
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.heightPercent,
    required this.label,
    required this.isToday,
  });

  final int heightPercent;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = isToday ? colors.accent : colors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: MinutesBarChart._trackHeight,
          child: Center(
            child: SizedBox(
              width: MinutesBarChart._barWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: AppRadii.rXs,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height:
                        MinutesBarChart._trackHeight *
                        (heightPercent.clamp(0, 100) / 100),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: AppRadii.rXs,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(label, style: AppText.caption.copyWith(color: colors.text3)),
      ],
    );
  }
}

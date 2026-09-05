import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Compact daily minutes chart: bars sized by [values] labelled with
/// [labels].
class HomeMinutesMini extends StatelessWidget {
  const HomeMinutesMini({
    super.key,
    required this.values,
    required this.labels,
    required this.todayIndex,
  });

  final List<int> values;
  final List<String> labels;
  final int todayIndex;

  static const double _trackHeight = 80;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _trackHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: AppRadii.rXs,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: values[i].clamp(0, 100) / 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i == todayIndex
                                ? colors.accent
                                : colors.primary,
                            borderRadius: AppRadii.rXs,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  labels[i],
                  style: AppText.caption.copyWith(color: colors.text3),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

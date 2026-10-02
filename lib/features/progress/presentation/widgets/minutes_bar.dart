import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// One day of the minutes chart: a bar and the weekday under it.
class MinutesBar extends StatelessWidget {
  const MinutesBar({
    super.key,
    required this.heightPercent,
    required this.label,
    required this.isToday,
  });

  final int heightPercent;
  final String label;
  final bool isToday;

  static const double _trackHeight = 120;
  static const double _barWidth = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = isToday ? colors.accent : colors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _trackHeight,
          child: Center(
            child: SizedBox(
              width: _barWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: AppRadii.rXs,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: _trackHeight * (heightPercent.clamp(0, 100) / 100),
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

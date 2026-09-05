import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Decorative wave on the brand panel.
class AuthBrandWave extends StatelessWidget {
  const AuthBrandWave({super.key});

  /// Bar width and the gap between bars, taken from the design.
  static const double _barWidth = 3;
  static const double _barGap = 2;

  /// Which part of the wave is drawn as played.
  static const double _playedFraction = 0.42;

  /// How short the smallest bar can be.
  static const double _minBarFraction = 0.24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: AppSizes.iconLg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count =
              ((constraints.maxWidth + _barGap) / (_barWidth + _barGap))
                  .floor();
          final played = (count * _playedFraction).round();

          return Row(
            spacing: _barGap,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(
                  width: _barWidth,
                  height: constraints.maxHeight * _barHeightFraction(i),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.rPill,
                      color: i <= played
                          ? colors.primaryOn
                          : colors.primaryOn.withValues(
                              alpha: AppOpacities.disabled,
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Two mismatched waves make a shape that reads as noise, not a pattern.
  double _barHeightFraction(int index) {
    final shape = (math.sin(index * 0.6) * math.cos(index * 0.33)).abs();
    return _minBarFraction + shape * (1 - _minBarFraction);
  }
}

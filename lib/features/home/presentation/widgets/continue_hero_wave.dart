import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Decorative equalizer on the card.
class ContinueHeroWave extends StatelessWidget {
  const ContinueHeroWave({super.key});

  static const double _barWidth = 3;
  static const double _barGap = 2;
  static const double _playedFraction = 0.4;
  static const double _minBarFraction = 0.28;

  @override
  Widget build(BuildContext context) {
    final onGrad = context.colors.primaryOn;

    return SizedBox(
      height: 26,
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
                          ? onGrad
                          : onGrad.withValues(alpha: 0.35),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _barHeightFraction(int index) {
    final shape = (math.sin(index * 0.7) * math.cos(index * 0.3)).abs();
    return _minBarFraction + shape * (1 - _minBarFraction);
  }
}

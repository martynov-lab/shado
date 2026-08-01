import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Волна на брендовой панели: полоски, у которых начало «пройдено».
/// Украшение, а не данные, — форма считается по индексу полоски.
class AuthBrandWave extends StatelessWidget {
  const AuthBrandWave({super.key});

  /// Ширина полоски и промежуток между ними — из макета.
  static const double _barWidth = 3;
  static const double _barGap = 2;

  /// Какая часть волны показана пройденной.
  static const double _playedFraction = 0.42;

  /// Насколько низкой бывает самая короткая полоска.
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

  /// Две несовпадающие волны дают рисунок, который не читается как узор.
  double _barHeightFraction(int index) {
    final shape = (math.sin(index * 0.6) * math.cos(index * 0.33)).abs();
    return _minBarFraction + shape * (1 - _minBarFraction);
  }
}

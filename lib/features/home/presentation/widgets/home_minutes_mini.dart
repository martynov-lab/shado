import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Компактный график минут по дням для боковой панели: тонкие столбцы без
/// подписей. [values] — высоты в процентах (0–100).
class HomeMinutesMini extends StatelessWidget {
  const HomeMinutesMini({super.key, required this.values});

  final List<int> values;

  static const double _height = 80;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s2),
            Expanded(
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
                        color: colors.primary,
                        borderRadius: AppRadii.rXs,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

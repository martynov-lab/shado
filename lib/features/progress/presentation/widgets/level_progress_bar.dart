import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Прогресс уровня: от текущего уровня к следующему, полоса заполнения и
/// подпись-подсказка снизу.
class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({
    super.key,
    required this.fromLevel,
    required this.toLevel,
    required this.ratio,
    required this.hint,
  });

  final String fromLevel;
  final String toLevel;

  /// Доля пройденного до следующего уровня, 0–1.
  final double ratio;

  final String hint;

  static const double _trackHeight = AppSpacing.s2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final levelStyle = AppText.label.copyWith(
      color: colors.text2,
      fontWeight: FontWeight.w800,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(fromLevel, style: levelStyle),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: AppRadii.rPill,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppBrand.signGradient,
                        borderRadius: AppRadii.rPill,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Text(toLevel, style: levelStyle),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(hint, style: AppText.caption.copyWith(color: colors.text3)),
      ],
    );
  }
}

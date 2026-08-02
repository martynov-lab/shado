import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Кольцо цели недели: круговой индикатор с процентом в центре и расшифровкой
/// справа (сделано / всего и сколько осталось).
class HomeGoalRing extends StatelessWidget {
  const HomeGoalRing({
    super.key,
    required this.ratio,
    required this.value,
    required this.remaining,
  });

  /// Доля выполненной цели, 0–1.
  final double ratio;

  /// Основная строка — «126 / 180 мин».
  final String value;

  /// Пояснение — «осталось 54 минуты».
  final String remaining;

  static const double _size = 64;
  static const double _stroke = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clamped = ratio.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Row(
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: _stroke,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.primarySoft,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              Text(
                '$percent%',
                style: AppText.caption.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppText.label.copyWith(color: colors.text)),
              const SizedBox(height: AppSpacing.s1),
              Text(
                remaining,
                style: AppText.caption.copyWith(color: colors.text3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

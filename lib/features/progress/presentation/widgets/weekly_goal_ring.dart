import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Кольцо цели недели: круговой индикатор с процентом в центре и расшифровкой
/// справа (сделано / всего и сколько осталось).
class WeeklyGoalRing extends StatelessWidget {
  const WeeklyGoalRing({
    super.key,
    required this.ratio,
    required this.value,
    required this.remaining,
  });

  /// Доля выполненной цели, 0–1.
  final double ratio;

  /// Основная строка — «126 / 180 мин».
  final String value;

  /// Пояснение — «осталось 54 мин».
  final String remaining;

  static const double _size = 70;
  static const double _stroke = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = (ratio.clamp(0.0, 1.0) * 100).round();

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
                  value: ratio.clamp(0.0, 1.0),
                  strokeWidth: _stroke,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.primarySoft,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              Text(
                '$percent%',
                style: AppText.label.copyWith(
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
              Text(value, style: AppText.title.copyWith(color: colors.text)),
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

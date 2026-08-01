import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Тонкая полоса прогресса разбора урока.
///
/// ЗАГЛУШКА: прогресс разбора пока не отслеживается в данных, поэтому [value]
/// по умолчанию `0` (полоса пустая). Оставлена ради вида из макета — заполнится,
/// когда появится подсчёт разобранных сегментов.
class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({super.key, this.value = 0});

  /// Доля разобранного, `0..1`.
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: AppRadii.rPill,
      child: Stack(
        children: [
          Container(height: 5, color: colors.waveOff),
          FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(height: 5, color: colors.primary),
          ),
        ],
      ),
    );
  }
}

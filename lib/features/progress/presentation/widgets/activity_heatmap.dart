import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Тепловая карта активности: 7 строк (дни недели) × 10 столбцов (недели).
///
/// [cells] — минуты за день по строкам (длина 7×[columns]); насыщенность ячейки
/// растёт с числом минут. Под сеткой — легенда «меньше → больше».
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.cells, this.columns = 10});

  final List<int> cells;
  final int columns;

  static const int _rows = 7;
  static const double _radius = 3;

  /// Насыщенность ячейки по минутам: чем больше занимался, тем плотнее primary.
  static double _alphaFor(int minutes) {
    if (minutes <= 0) return 0.08;
    if (minutes <= 8) return 0.30;
    if (minutes <= 18) return 0.55;
    if (minutes <= 30) return 0.78;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < _rows; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r == _rows - 1 ? 0 : AppSpacing.s1),
            child: Row(
              children: [
                for (var c = 0; c < columns; c++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: c == columns - 1 ? 0 : AppSpacing.s1,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _Cell(minutes: _valueAt(r, c), colors: colors),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s3),
        _Legend(colors: colors),
      ],
    );
  }

  int _valueAt(int row, int col) {
    final index = row * columns + col;
    return index < cells.length ? cells[index] : 0;
  }
}

/// Ячейка карты: насыщенность растёт с минутами, а в дни с активностью внутри
/// показываем сами минуты. На тёмных ячейках подпись светлая, на светлых —
/// основным цветом текста; [FittedBox] ужимает число под размер ячейки.
class _Cell extends StatelessWidget {
  const _Cell({required this.minutes, required this.colors});

  final int minutes;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final alpha = ActivityHeatmap._alphaFor(minutes);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(ActivityHeatmap._radius),
      ),
      child: minutes <= 0
          ? null
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s1),
                child: FittedBox(
                  child: Text(
                    '$minutes',
                    style: AppText.caption.copyWith(
                      color: alpha >= 0.78 ? colors.primaryOn : colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final captionStyle = AppText.caption.copyWith(color: colors.text3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('меньше', style: captionStyle),
        const SizedBox(width: AppSpacing.s2),
        for (final alpha in const [0.30, 0.55, 0.78, 1.0])
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s1),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(ActivityHeatmap._radius),
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.s1),
        Text('больше', style: captionStyle),
      ],
    );
  }
}

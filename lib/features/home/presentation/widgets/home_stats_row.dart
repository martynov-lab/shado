import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'home_stat.dart';

/// Ряд плиток статистики. Каждый кортеж — подпись, число, единица (или `null`),
/// дельта.
///
/// В узкой раскладке ([scrollable]) плитки фиксированной ширины и прокручиваются
/// вбок; иначе делят ширину поровну.
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.stats,
    this.scrollable = false,
  });

  final List<(String, String, String?, String)> stats;
  final bool scrollable;

  /// Ширина плитки в прокручиваемом режиме.
  static const double _tileWidth = 150;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s3),
                SizedBox(width: _tileWidth, child: _tile(stats[i])),
              ],
            ],
          ),
        ),
      );
    }

    // IntrinsicHeight задаёт ряду конечную высоту, поэтому `stretch` выравнивает
    // плитки по самой высокой, а не требует бесконечную высоту в прокрутке.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s3),
            Expanded(child: _tile(stats[i])),
          ],
        ],
      ),
    );
  }

  HomeStat _tile((String, String, String?, String) stat) => HomeStat(
    caption: stat.$1,
    value: stat.$2,
    unit: stat.$3,
    delta: stat.$4,
  );
}

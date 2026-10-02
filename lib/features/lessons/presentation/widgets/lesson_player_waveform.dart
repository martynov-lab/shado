import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Player panel waveform; the bars are decorative, the played part follows
/// [playedFraction].
class LessonPlayerWaveform extends StatelessWidget {
  const LessonPlayerWaveform({
    super.key,
    required this.color,
    required this.playedFraction,
    this.height = 56,
  });

  /// Color of played bars; unplayed ones use a dimmed variant.
  final Color color;

  /// `0..1` of the shown range.
  final double playedFraction;

  final double height;

  @override
  Widget build(BuildContext context) {
    final off = color.withValues(alpha: 0.22);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const barWidth = 3.0;
          const gap = 3.0;
          final width = constraints.maxWidth;
          final count = width.isFinite
              ? ((width + gap) ~/ (barWidth + gap))
              : 0;
          if (count <= 0) return const SizedBox.shrink();
          final onCount = (count * playedFraction).round();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == count - 1 ? 0 : gap),
                  child: Container(
                    width: barWidth,
                    height: _barHeight(i),
                    decoration: BoxDecoration(
                      color: i < onCount ? color : off,
                      borderRadius: AppRadii.rXs,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _barHeight(int i) {
    final wave = (math.sin(i * 0.7) * math.cos(i * 0.35)).abs();
    return height * (0.18 + wave * 0.82);
  }
}

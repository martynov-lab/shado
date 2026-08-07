import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/lesson_controller.dart';

/// Волна аудио на панели плеера с курсором текущей позиции.
///
/// Форма столбиков декоративная (детерминированная функция, а не реальные
/// пики), но заливка «сыгранного» двигается по позиции воспроизведения:
/// в пределах текущего сегмента столбики слева от курсора подсвечены. Пока
/// сегмент не играет, курсор стоит в начале.
class LessonPlayerWaveform extends ConsumerWidget {
  const LessonPlayerWaveform({
    super.key,
    required this.lessonId,
    required this.color,
    this.height = 56,
  });

  /// Цвет «сыгранных» столбиков; несыгранные — он же, но приглушённый.
  final Color color;
  final double height;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Границы показанного отрезка и признак «играет» — перестраиваемся только
    // при их смене, не на каждом тике позиции.
    final segment = ref.watch(
      lessonControllerProvider(lessonId).select((async) {
        final state = async.value;
        if (state == null) return null;
        return (
          start: state.playerStartMs,
          end: state.playerEndMs,
          playing: state.isPlayerPlaying,
        );
      }),
    );
    // Позицию слушаем всегда, а применяем только на проигрывании.
    final positionMs = ref.watch(lessonPositionMsProvider(lessonId));

    var fraction = 0.0;
    if (segment != null && segment.playing) {
      final duration = segment.end - segment.start;
      if (duration > 0) {
        fraction = ((positionMs - segment.start) / duration).clamp(0.0, 1.0);
      }
    }

    return _WaveformBars(color: color, height: height, playedFraction: fraction);
  }
}

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({
    required this.color,
    required this.height,
    required this.playedFraction,
  });

  final Color color;
  final double height;
  final double playedFraction;

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
          final count = width.isFinite ? ((width + gap) ~/ (barWidth + gap)) : 0;
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

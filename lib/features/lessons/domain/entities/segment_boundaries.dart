import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';

/// Работа с набором границ кусков.
///
/// Границы общие: для `N` кусков это `N + 1` значение, где `b[0] = 0`,
/// `b[N] = durationMs`, а между ними — внутренние стыки, которые пользователь
/// двигает на волне.
class SegmentBoundaries {
  const SegmentBoundaries._();

  /// Равномерная раскладка на [count] кусков.
  static List<int> even(int count, int durationMs) {
    if (count <= 0 || durationMs <= 0) return const [];
    return [for (var i = 0; i <= count; i++) durationMs * i ~/ count];
  }

  /// Подгоняет уже расставленные границы под новое число кусков.
  ///
  /// Разметка обычно правится с начала текста, поэтому уцелевшие внутренние
  /// стыки переносятся как есть, а хвост аудио делится поровну между
  /// оставшимися кусками.
  static List<int> resize(List<int> current, int count, int durationMs) {
    if (count <= 0 || durationMs <= 0) return const [];
    if (current.length < 2) return even(count, durationMs);

    final result = <int>[
      for (var i = 0; i < math.min(current.length - 1, count); i++) current[i],
    ];
    final rest = count - (result.length - 1);
    final from = result.last;
    final span = durationMs - from;
    for (var i = 1; i <= rest; i++) {
      result.add(from + span * i ~/ rest);
    }
    return normalize(result, durationMs);
  }

  /// Прижимает крайние границы к краям аудио и разводит соседние минимум на
  /// [kMinSegmentGapMs].
  static List<int> normalize(List<int> boundaries, int durationMs) {
    if (boundaries.length < 2) {
      throw const ValidationFailure('Границ должно быть не меньше двух');
    }
    final result = List<int>.of(boundaries);
    result[0] = 0;
    result[result.length - 1] = durationMs;
    for (var i = 1; i < result.length - 1; i++) {
      final lowerLimit = result[i - 1] + kMinSegmentGapMs;
      // На очень коротком аудио минимальный зазор может не поместиться —
      // тогда границы просто идут подряд с шагом в 1 мс.
      final upperLimit = math.max(
        lowerLimit,
        durationMs - kMinSegmentGapMs * (result.length - 1 - i),
      );
      result[i] = result[i].clamp(lowerLimit, upperLimit);
    }
    return result;
  }
}

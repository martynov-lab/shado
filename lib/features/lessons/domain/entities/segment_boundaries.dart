import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import 'audio_trim.dart';

/// Работа с набором границ кусков.
///
/// Границы общие: для `N` кусков это `N + 1` значение, где `b[0]` и `b[N]`
/// прибиты к краям обрезанного отрезка [AudioTrim], а между ними — внутренние
/// стыки, которые пользователь двигает на волне. Значения — абсолютные
/// миллисекунды файла, поэтому обрезка головы не сдвигает уже расставленные
/// метки.
class SegmentBoundaries {
  const SegmentBoundaries._();

  /// Равномерная раскладка на [count] кусков внутри [trim].
  static List<int> even(int count, AudioTrim trim) {
    if (count <= 0 || trim.isEmpty) return const [];
    return [
      for (var i = 0; i <= count; i++)
        trim.startMs + trim.durationMs * i ~/ count,
    ];
  }

  /// Подгоняет уже расставленные границы под новое число кусков и под [trim].
  ///
  /// Разметка обычно правится с начала текста, поэтому уцелевшие внутренние
  /// стыки переносятся как есть, а хвост аудио делится поровну между
  /// оставшимися кусками.
  static List<int> resize(List<int> current, int count, AudioTrim trim) {
    if (count <= 0 || trim.isEmpty) return const [];
    if (current.length < 2) return even(count, trim);

    return _spreadRest(
      [
        for (var i = 0; i < math.min(current.length - 1, count); i++)
          current[i],
      ],
      count,
      trim,
    );
  }

  /// Переносит разметку на новую обрезку, не меняя числа кусков.
  ///
  /// Метки внутри нового отрезка остаются на своих местах: они привязаны к
  /// речи, и обрезка тишины по краям их не касается. А вот метки, оказавшиеся
  /// снаружи, размечали как раз то, что отрезали, — прижимать их к краю значит
  /// наделать кусков по 200 мс, поэтому они делят поровну освободившееся место
  /// с той же стороны.
  static List<int> refit(List<int> current, AudioTrim trim) {
    if (current.length < 2 || trim.isEmpty) return current;
    final count = current.length - 1;
    final inner = current.sublist(1, count);
    final kept = <int>[
      for (final ms in inner)
        if (ms > trim.startMs && ms < trim.endMs) ms,
    ];
    final orphanedBefore = inner.where((ms) => ms <= trim.startMs).length;
    final orphanedAfter = inner.length - kept.length - orphanedBefore;

    final result = <int>[trim.startMs];
    // Слева от первой уцелевшей метки — столько кусков, сколько осталось без
    // места в отрезанной голове.
    final firstKept = kept.isEmpty ? trim.endMs : kept.first;
    for (var i = 1; i <= orphanedBefore; i++) {
      result.add(
        trim.startMs + (firstKept - trim.startMs) * i ~/ (orphanedBefore + 1),
      );
    }
    result.addAll(kept);
    // Так же и с хвостом: делим то, что осталось после последней уцелевшей.
    final lastKept = kept.isEmpty ? result.last : kept.last;
    for (var i = 1; i <= orphanedAfter; i++) {
      result.add(lastKept + (trim.endMs - lastKept) * i ~/ (orphanedAfter + 1));
    }
    result.add(trim.endMs);
    return normalize(result, trim);
  }

  /// Дописывает недостающие метки, поровну деля хвост отрезка за [head].
  static List<int> _spreadRest(List<int> head, int count, AudioTrim trim) {
    final result = List<int>.of(head);
    final rest = count - (result.length - 1);
    final from = result.last;
    final span = trim.endMs - from;
    for (var i = 1; i <= rest; i++) {
      result.add(from + span * i ~/ rest);
    }
    return normalize(result, trim);
  }

  /// Прижимает крайние границы к краям [trim] и разводит соседние минимум на
  /// [kMinSegmentGapMs].
  ///
  /// Через неё же разметка переезжает на новую обрезку: метки, оказавшиеся за
  /// её пределами, подтягиваются внутрь.
  static List<int> normalize(List<int> boundaries, AudioTrim trim) {
    if (boundaries.length < 2) {
      throw const ValidationFailure('Границ должно быть не меньше двух');
    }
    final count = boundaries.length - 1;
    // На очень коротком отрезке минимальный зазор не помещается — тогда куски
    // просто делят его поровну.
    if (trim.durationMs <= count) return even(count, trim);

    final gap = _gapMs(count, trim.durationMs);
    final result = List<int>.of(boundaries);
    result[0] = trim.startMs;
    result[count] = trim.endMs;
    for (var i = 1; i < count; i++) {
      final lowerLimit = result[i - 1] + gap;
      final upperLimit = trim.endMs - gap * (count - i);
      result[i] = result[i].clamp(lowerLimit, math.max(lowerLimit, upperLimit));
    }
    return result;
  }

  /// Зазор, который гарантированно помещается [count] раз: на коротком отрезке
  /// минимальный уступает место, иначе куски не разложить.
  static int _gapMs(int count, int durationMs) =>
      math.min(kMinSegmentGapMs, math.max(1, durationMs ~/ count));
}

import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import 'audio_trim.dart';

/// Segment boundary math: `N` segments give `N + 1` values in absolute file
/// milliseconds.
class SegmentBoundaries {
  const SegmentBoundaries._();

  /// Even layout of [count] segments inside [trim].
  static List<int> even(int count, AudioTrim trim) {
    if (count <= 0 || trim.isEmpty) return const [];
    return [
      for (var i = 0; i <= count; i++)
        trim.startMs + trim.durationMs * i ~/ count,
    ];
  }

  /// Fits existing boundaries to a new segment count and to [trim].
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

  /// Refits the layout to a new trim without changing the segment count:
  /// inner markers stay, outer ones split the freed room evenly.
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
    // On the left, split the room among markers cut off by the trimmed head.
    final firstKept = kept.isEmpty ? trim.endMs : kept.first;
    for (var i = 1; i <= orphanedBefore; i++) {
      result.add(
        trim.startMs + (firstKept - trim.startMs) * i ~/ (orphanedBefore + 1),
      );
    }
    result.addAll(kept);
    // The tail is handled the same way.
    final lastKept = kept.isEmpty ? result.last : kept.last;
    for (var i = 1; i <= orphanedAfter; i++) {
      result.add(lastKept + (trim.endMs - lastKept) * i ~/ (orphanedAfter + 1));
    }
    result.add(trim.endMs);
    return normalize(result, trim);
  }

  /// Inserts inner marker [ordinal] at [ms], growing the layout by one
  /// segment; the other markers stay in place.
  static List<int> insertAt(
    List<int> current,
    int ordinal,
    int ms,
    AudioTrim trim,
  ) {
    if (current.length < 2 || trim.isEmpty) return current;
    if (ordinal < 1 || ordinal > current.length - 1) return current;
    final grown = [...current.sublist(0, ordinal), ms, ...current.sublist(ordinal)];
    // normalize snaps the marker to the previous one when [ms] breaks the gap.
    return normalize(grown, trim);
  }

  /// Position of the previous marker — where marker [ordinal] goes when it is
  /// not pinned to the playhead.
  static int afterPrevious(List<int> current, int ordinal) => current.isEmpty
      ? 0
      : current[(ordinal - 1).clamp(0, current.length - 1)];

  /// Appends the missing markers, splitting the tail after [head] evenly.
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

  /// Snaps the outer boundaries to [trim] and keeps neighbours at least
  /// [kMinSegmentGapMs].
  static List<int> normalize(List<int> boundaries, AudioTrim trim) {
    if (boundaries.length < 2) {
      throw const ValidationFailure('Границ должно быть не меньше двух');
    }
    final count = boundaries.length - 1;
    // On a short range the gap does not fit — split it evenly.
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

  /// A gap that fits between boundaries [count] times.
  static int _gapMs(int count, int durationMs) =>
      math.min(kMinSegmentGapMs, math.max(1, durationMs ~/ count));
}

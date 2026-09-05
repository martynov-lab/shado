import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment.dart';

/// Segment count label with the right plural form.
String segmentsLabel(int count) {
  final word = _segmentsWord(count);
  return '$count $word';
}

String _segmentsWord(int count) {
  if (count % 100 >= 11 && count % 100 <= 14) return 'сегментов';
  return switch (count % 10) {
    1 => 'сегмент',
    2 || 3 || 4 => 'сегмента',
    _ => 'сегментов',
  };
}

/// Lesson count label for a folder with the right plural form.
String lessonsLabel(int count) {
  final word = _lessonsWord(count);
  return '$count $word';
}

String _lessonsWord(int count) {
  if (count % 100 >= 11 && count % 100 <= 14) return 'уроков';
  return switch (count % 10) {
    1 => 'урок',
    2 || 3 || 4 => 'урока',
    _ => 'уроков',
  };
}

/// Segment ordinal with a leading zero: `01`, `02`, …
String segmentNumber(int index) => (index + 1).toString().padLeft(2, '0');

/// Segment bounds in minutes and seconds without fractions.
String segmentTimecodes(Segment segment) =>
    rangeTimecodes(segment.startMs, segment.endMs);

/// Range bounds from the first segment start to the last segment end.
String rangeTimecodes(int startMs, int endMs) =>
    '${_clock(startMs)}–${_clock(endMs)}';

String _clock(int milliseconds) {
  final total = milliseconds < 0 ? 0 : milliseconds;
  final minutes = total ~/ 60000;
  final seconds = (total % 60000) ~/ 1000;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Lesson subtitle such as topic, segment count and level; empty fields are
/// skipped.
String lessonSubtitle(Lesson lesson) {
  return [
    if (lesson.topic != null && lesson.topic!.name.isNotEmpty) lesson.topic!.name,
    segmentsLabel(lesson.segmentCount),
    if (lesson.level != null) lesson.level!.wire.toUpperCase(),
  ].join(' · ');
}

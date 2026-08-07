import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment.dart';

/// «12 сегментов» с правильным окончанием. В UI урок нарезан на сегменты —
/// придерживаемся этого слова во всех новых экранах вслед за макетом.
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

/// Порядковый номер сегмента с ведущим нулём: `01`, `02`, …
String segmentNumber(int index) => (index + 1).toString().padLeft(2, '0');

/// Границы сегмента «0:04–0:12» (минуты:секунды, без долей).
String segmentTimecodes(Segment segment) =>
    rangeTimecodes(segment.startMs, segment.endMs);

/// Границы отрезка «0:04–0:20» по началу первого и концу последнего куска.
String rangeTimecodes(int startMs, int endMs) =>
    '${_clock(startMs)}–${_clock(endMs)}';

String _clock(int milliseconds) {
  final total = milliseconds < 0 ? 0 : milliseconds;
  final minutes = total ~/ 60000;
  final seconds = (total % 60000) ~/ 1000;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Подзаголовок строки/карточки урока: «Подкаст · 12 сегментов · B1».
///
/// Пропускает поля, которых нет: у урока без темы или уровня строка просто
/// короче.
String lessonSubtitle(Lesson lesson) {
  return [
    if (lesson.topic != null && lesson.topic!.name.isNotEmpty) lesson.topic!.name,
    segmentsLabel(lesson.segmentCount),
    if (lesson.level != null) lesson.level!.wire.toUpperCase(),
  ].join(' · ');
}

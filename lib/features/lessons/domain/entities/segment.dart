/// Кусок урока: фрагмент текста и его границы на аудио.
///
/// Границы кусков общие (встык), поэтому `endMs` одного сегмента равен
/// `startMs` следующего.
class Segment {
  const Segment({
    required this.index,
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  /// Порядковый номер, 0-based.
  final int index;
  final String text;
  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;

  Segment copyWith({int? index, String? text, int? startMs, int? endMs}) {
    return Segment(
      index: index ?? this.index,
      text: text ?? this.text,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Segment &&
          other.index == index &&
          other.text == text &&
          other.startMs == startMs &&
          other.endMs == endMs;

  @override
  int get hashCode => Object.hash(index, text, startMs, endMs);

  @override
  String toString() => 'Segment($index, $startMs..$endMs, "$text")';
}

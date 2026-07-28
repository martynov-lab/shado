/// Непрерывный набор кусков урока: отрезок `[start, end]`, оба конца
/// включительно.
///
/// Выбрать можно только соседние куски (или все сразу) — иначе непонятно, что
/// значит «проиграть выбранное». Зато у отрезка есть приятное свойство: соседние
/// куски идут встык, поэтому любой отрезок — это один непрерывный фрагмент
/// аудио, который плеер играет и зацикливает как обычный кусок.
class SegmentRange {
  const SegmentRange(this.start, this.end) : assert(start <= end);

  const SegmentRange.single(int index) : start = index, end = index;

  final int start;
  final int end;

  int get length => end - start + 1;

  bool get isSingle => start == end;

  bool contains(int index) => index >= start && index <= end;

  /// Отрезок между куском, с которого начали выделять, и текущим: выделение
  /// растёт и убывает в обе стороны от [anchor].
  static SegmentRange between(int anchor, int index) => anchor <= index
      ? SegmentRange(anchor, index)
      : SegmentRange(index, anchor);

  /// Каким станет выделение [selection] после тапа по куску [index].
  ///
  /// Разорвать отрезок нельзя, поэтому ходов немного: сосед расширяет
  /// выделение, край — снимает, а кусок из середины или вдалеке начинает
  /// выделение заново.
  static SegmentRange? toggled(SegmentRange? selection, int index) {
    if (selection == null) return SegmentRange.single(index);
    if (selection.contains(index)) {
      if (selection.isSingle) return null;
      if (index == selection.start) {
        return SegmentRange(index + 1, selection.end);
      }
      if (index == selection.end) {
        return SegmentRange(selection.start, index - 1);
      }
      return SegmentRange.single(index);
    }
    if (index == selection.start - 1) return SegmentRange(index, selection.end);
    if (index == selection.end + 1) return SegmentRange(selection.start, index);
    return SegmentRange.single(index);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SegmentRange($start..$end)';
}

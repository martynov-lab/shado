import '../../../../../core/constants/app_constants.dart';

/// Разбивка текста на сегменты — это символы [kSegmentDelimiter] в «сырой»
/// строке. Метку можно поставить в любую позицию каретки, поэтому все операции
/// работают с индексами символов, а не с зазорами между словами.

/// Индексы всех разделителей в тексте — по одному на каждую метку.
List<int> markerIndices(String text) {
  final result = <int>[];
  for (var i = 0; i < text.length; i++) {
    if (text[i] == kSegmentDelimiter) result.add(i);
  }
  return result;
}

/// Ставит разделитель в позицию каретки [caret]. Вплотную к уже стоящей метке
/// второй не ставит — иначе появился бы пустой сегмент.
String insertMarkerAt(String text, int caret) {
  final at = caret.clamp(0, text.length);
  if (at > 0 && text[at - 1] == kSegmentDelimiter) return text;
  if (at < text.length && text[at] == kSegmentDelimiter) return text;
  return text.substring(0, at) + kSegmentDelimiter + text.substring(at);
}

/// Индекс каретки сразу за только что вставленной в [caret] меткой.
int caretAfterInsert(int caret) => caret + 1;

/// Убирает разделитель на позиции [index]. Если по обе стороны от него были
/// пробелы, задвоённый пробел схлопывается до одного.
String removeMarker(String text, int index) {
  if (index < 0 || index >= text.length || text[index] != kSegmentDelimiter) {
    return text;
  }
  final before = text.substring(0, index);
  var after = text.substring(index + 1);
  if (before.endsWith(' ') && after.startsWith(' ')) {
    after = after.substring(1);
  }
  return before + after;
}

/// Переносит разделитель с позиции [fromIndex] в позицию каретки [toCaret].
String moveMarker(String text, int fromIndex, int toCaret) {
  if (fromIndex < 0 ||
      fromIndex >= text.length ||
      text[fromIndex] != kSegmentDelimiter) {
    return text;
  }
  // Обе каретки вплотную к самой метке — это та же точка, ничего не меняем.
  if (toCaret == fromIndex || toCaret == fromIndex + 1) return text;
  final without = removeMarker(text, fromIndex);
  // Сколько символов ушло слева от цели (сам «|» и, возможно, лишний пробел).
  final removed = text.length - without.length;
  final target = toCaret > fromIndex ? toCaret - removed : toCaret;
  return insertMarkerAt(without, target);
}

/// Снимает все разделители, схлопывая задвоённые пробелы.
String clearMarkers(String text) {
  if (!text.contains(kSegmentDelimiter)) return text;
  return text
      .replaceAll(kSegmentDelimiter, '')
      .replaceAll(RegExp(r' {2,}'), ' ');
}

import '../../../../../core/constants/app_constants.dart';

/// Operations on [kSegmentDelimiter] delimiters by character index.

/// Indexes of every delimiter in the text, one per marker.
List<int> markerIndices(String text) {
  final result = <int>[];
  for (var i = 0; i < text.length; i++) {
    if (text[i] == kSegmentDelimiter) result.add(i);
  }
  return result;
}

/// Puts a delimiter at caret [caret]; never right next to another marker.
String insertMarkerAt(String text, int caret) {
  final at = caret.clamp(0, text.length);
  if (at > 0 && text[at - 1] == kSegmentDelimiter) return text;
  if (at < text.length && text[at] == kSegmentDelimiter) return text;
  return text.substring(0, at) + kSegmentDelimiter + text.substring(at);
}

/// Caret index right after the marker just inserted at [caret].
int caretAfterInsert(int caret) => caret + 1;

/// Removes the delimiter at [index] and collapses a doubled space.
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

/// Moves a delimiter from [fromIndex] to caret position [toCaret].
String moveMarker(String text, int fromIndex, int toCaret) {
  if (fromIndex < 0 ||
      fromIndex >= text.length ||
      text[fromIndex] != kSegmentDelimiter) {
    return text;
  }
  // Both carets touch the marker itself — same spot, nothing changes.
  if (toCaret == fromIndex || toCaret == fromIndex + 1) return text;
  final without = removeMarker(text, fromIndex);
  // How many characters were dropped left of the target: the delimiter and
  // possibly an extra space.
  final removed = text.length - without.length;
  final target = toCaret > fromIndex ? toCaret - removed : toCaret;
  return insertMarkerAt(without, target);
}

/// Removes every delimiter and collapses doubled spaces.
String clearMarkers(String text) {
  if (!text.contains(kSegmentDelimiter)) return text;
  return text
      .replaceAll(kSegmentDelimiter, '')
      .replaceAll(RegExp(r' {2,}'), ' ');
}

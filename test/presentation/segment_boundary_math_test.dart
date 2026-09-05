import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/segment_boundary_math.dart';

/// Index operations on delimiters inside a text string.
void main() {
  group('markerIndices', () {
    test('находит все разделители', () {
      expect(markerIndices('a|b|c'), [1, 3]);
      expect(markerIndices('no markers'), isEmpty);
    });
  });

  group('insertMarkerAt', () {
    test('ставит метку в позицию каретки', () {
      expect(insertMarkerAt('one two', 3), 'one| two');
      // Even mid-word: the marker lands exactly where it was put.
      expect(insertMarkerAt('word', 2), 'wo|rd');
      expect(caretAfterInsert(3), 4);
    });

    test('вплотную к существующей метке второй не ставит', () {
      expect(insertMarkerAt('one| two', 3), 'one| two');
      expect(insertMarkerAt('one| two', 4), 'one| two');
    });
  });

  group('removeMarker', () {
    test('убирает метку и схлопывает задвоённый пробел', () {
      expect(removeMarker('one | two', 4), 'one two');
    });

    test('в середине слова просто убирает символ', () {
      expect(removeMarker('wo|rd', 2), 'word');
    });

    test('индекс не на метке — строку не трогает', () {
      expect(removeMarker('one|two', 0), 'one|two');
    });
  });

  group('moveMarker', () {
    test('переносит метку в новую позицию каретки', () {
      // Moves the marker from index 3 to the position before the third word.
      expect(moveMarker('one| two three', 3, 8), 'one two| three');
    });

    test('перенос в ту же точку ничего не меняет', () {
      expect(moveMarker('one| two', 3, 3), 'one| two');
      expect(moveMarker('one| two', 3, 4), 'one| two');
    });
  });

  test('clearMarkers снимает все метки без двойных пробелов', () {
    expect(clearMarkers('one | two | three'), 'one two three');
    expect(clearMarkers('wo|rd'), 'word');
    expect(clearMarkers('one two'), 'one two');
  });
}

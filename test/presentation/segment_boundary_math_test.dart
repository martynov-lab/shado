import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/segment_boundary_math.dart';

/// Index operations on delimiters inside a text string.
void main() {
  group('markerIndices', () {
    test('finds every separator', () {
      expect(markerIndices('a|b|c'), [1, 3]);
      expect(markerIndices('no markers'), isEmpty);
    });
  });

  group('insertMarkerAt', () {
    test('places a marker at the caret position', () {
      expect(insertMarkerAt('one two', 3), 'one| two');
      // Even mid-word: the marker lands exactly where it was put.
      expect(insertMarkerAt('word', 2), 'wo|rd');
      expect(caretAfterInsert(3), 4);
    });

    test('does not place a second marker right next to an existing one', () {
      expect(insertMarkerAt('one| two', 3), 'one| two');
      expect(insertMarkerAt('one| two', 4), 'one| two');
    });
  });

  group('removeMarker', () {
    test('removes a marker and collapses the doubled space', () {
      expect(removeMarker('one | two', 4), 'one two');
    });

    test('in the middle of a word it just removes the character', () {
      expect(removeMarker('wo|rd', 2), 'word');
    });

    test('an index that is not on a marker leaves the string alone', () {
      expect(removeMarker('one|two', 0), 'one|two');
    });
  });

  group('moveMarker', () {
    test('moves a marker to the new caret position', () {
      // Moves the marker from index 3 to the position before the third word.
      expect(moveMarker('one| two three', 3, 8), 'one two| three');
    });

    test('moving to the same point changes nothing', () {
      expect(moveMarker('one| two', 3, 3), 'one| two');
      expect(moveMarker('one| two', 3, 4), 'one| two');
    });
  });

  test('clearMarkers removes every marker without leaving double spaces', () {
    expect(clearMarkers('one | two | three'), 'one two three');
    expect(clearMarkers('wo|rd'), 'word');
    expect(clearMarkers('one two'), 'one two');
  });
}

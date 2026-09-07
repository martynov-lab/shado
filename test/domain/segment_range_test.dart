import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/segment_range.dart';

void main() {
  group('SegmentRange', () {
    test('knows its own length and contents', () {
      const range = SegmentRange(2, 4);

      expect(range.length, 3);
      expect(range.isSingle, isFalse);
      expect(range.contains(2), isTrue);
      expect(range.contains(4), isTrue);
      expect(range.contains(1), isFalse);
      expect(range.contains(5), isFalse);
    });

    test('a single segment is a range of length one', () {
      const range = SegmentRange.single(3);

      expect(range.length, 1);
      expect(range.isSingle, isTrue);
      expect(range, const SegmentRange(3, 3));
    });

    test('between grows both ways from the anchor', () {
      expect(SegmentRange.between(2, 5), const SegmentRange(2, 5));
      expect(SegmentRange.between(5, 2), const SegmentRange(2, 5));
      expect(SegmentRange.between(3, 3), const SegmentRange.single(3));
    });
  });

  group('SegmentRange.toggled', () {
    test('with no selection it picks a single segment', () {
      expect(SegmentRange.toggled(null, 4), const SegmentRange.single(4));
    });

    test('tapping the only selected segment again clears the selection', () {
      expect(SegmentRange.toggled(const SegmentRange.single(4), 4), isNull);
    });

    test('a neighbour extends the selection from either side', () {
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 5),
        const SegmentRange(2, 5),
      );
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 1),
        const SegmentRange(1, 4),
      );
    });

    test('a tap on the selection edge drops that segment', () {
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 2),
        const SegmentRange(3, 4),
      );
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 4),
        const SegmentRange(2, 3),
      );
    });

    test('a segment from the middle starts a new selection instead of tearing it', () {
      expect(
        SegmentRange.toggled(const SegmentRange(1, 5), 3),
        const SegmentRange.single(3),
      );
    });

    test('a non-adjacent segment starts the selection over', () {
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 8),
        const SegmentRange.single(8),
      );
    });

    test('the selection always stays contiguous', () {
      SegmentRange? selection;
      for (final index in [3, 4, 5, 1, 2, 3, 9, 8]) {
        selection = SegmentRange.toggled(selection, index);
        if (selection == null) continue;
        expect(selection.start, lessThanOrEqualTo(selection.end));
      }
    });
  });
}

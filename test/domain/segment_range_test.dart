import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/segment_range.dart';

void main() {
  group('SegmentRange', () {
    test('знает свою длину и содержимое', () {
      const range = SegmentRange(2, 4);

      expect(range.length, 3);
      expect(range.isSingle, isFalse);
      expect(range.contains(2), isTrue);
      expect(range.contains(4), isTrue);
      expect(range.contains(1), isFalse);
      expect(range.contains(5), isFalse);
    });

    test('один кусок — отрезок длиной один', () {
      const range = SegmentRange.single(3);

      expect(range.length, 1);
      expect(range.isSingle, isTrue);
      expect(range, const SegmentRange(3, 3));
    });

    test('between растёт в обе стороны от точки отсчёта', () {
      expect(SegmentRange.between(2, 5), const SegmentRange(2, 5));
      expect(SegmentRange.between(5, 2), const SegmentRange(2, 5));
      expect(SegmentRange.between(3, 3), const SegmentRange.single(3));
    });
  });

  group('SegmentRange.toggled', () {
    test('без выделения выбирает один кусок', () {
      expect(SegmentRange.toggled(null, 4), const SegmentRange.single(4));
    });

    test('повторный тап по единственному куску снимает выделение', () {
      expect(SegmentRange.toggled(const SegmentRange.single(4), 4), isNull);
    });

    test('сосед расширяет выделение с любой стороны', () {
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 5),
        const SegmentRange(2, 5),
      );
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 1),
        const SegmentRange(1, 4),
      );
    });

    test('тап по краю выделения снимает этот кусок', () {
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 2),
        const SegmentRange(3, 4),
      );
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 4),
        const SegmentRange(2, 3),
      );
    });

    test('кусок из середины не рвёт выделение, а начинает новое', () {
      expect(
        SegmentRange.toggled(const SegmentRange(1, 5), 3),
        const SegmentRange.single(3),
      );
    });

    test('несоседний кусок начинает выделение заново', () {
      expect(
        SegmentRange.toggled(const SegmentRange(2, 4), 8),
        const SegmentRange.single(8),
      );
    });

    test('выделение всегда остаётся непрерывным', () {
      SegmentRange? selection;
      for (final index in [3, 4, 5, 1, 2, 3, 9, 8]) {
        selection = SegmentRange.toggled(selection, index);
        if (selection == null) continue;
        expect(selection.start, lessThanOrEqualTo(selection.end));
      }
    });
  });
}

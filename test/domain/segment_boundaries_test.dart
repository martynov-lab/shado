import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/lessons/domain/entities/segment_boundaries.dart';

void main() {
  group('SegmentBoundaries.even', () {
    test('делит аудио поровну и встык', () {
      expect(SegmentBoundaries.even(3, 9000), [0, 3000, 6000, 9000]);
    });

    test('без кусков или без длительности границ нет', () {
      expect(SegmentBoundaries.even(0, 9000), isEmpty);
      expect(SegmentBoundaries.even(3, 0), isEmpty);
    });
  });

  group('SegmentBoundaries.resize', () {
    test('оставляет разметку как есть, если число кусков не изменилось', () {
      final current = [0, 1000, 7000, 9000];

      expect(SegmentBoundaries.resize(current, 3, 9000), current);
    });

    test('при добавлении куска сохраняет уже расставленные метки', () {
      final result = SegmentBoundaries.resize([0, 1000, 7000, 9000], 4, 9000);

      expect(result.take(3), [0, 1000, 7000]);
      expect(result.length, 5);
      expect(result.last, 9000);
    });

    test('при удалении куска сохраняет метки с начала', () {
      final result = SegmentBoundaries.resize([0, 1000, 7000, 9000], 2, 9000);

      expect(result, [0, 1000, 9000]);
    });

    test('пустую разметку раскладывает равномерно', () {
      expect(SegmentBoundaries.resize(const [], 3, 9000), [
        0,
        3000,
        6000,
        9000,
      ]);
    });

    test('разводит метки минимум на kMinSegmentGapMs', () {
      final result = SegmentBoundaries.resize([0, 100], 3, 600);

      for (var i = 1; i < result.length; i++) {
        expect(result[i] - result[i - 1], greaterThanOrEqualTo(1));
      }
      expect(result.first, 0);
      expect(result.last, 600);
      expect(result[1], greaterThanOrEqualTo(kMinSegmentGapMs));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/lessons/domain/usecases/update_segment_boundaries.dart';

void main() {
  group('UpdateSegmentBoundaries.normalize', () {
    test('прижимает крайние границы к краям аудио', () {
      final result = UpdateSegmentBoundaries.normalize([
        500,
        3000,
        8000,
      ], 9000);

      expect(result.first, 0);
      expect(result.last, 9000);
    });

    test('разводит соседние границы минимум на kMinSegmentGapMs', () {
      final result = UpdateSegmentBoundaries.normalize([
        0,
        1000,
        1000,
        9000,
      ], 9000);

      expect(result[2] - result[1], greaterThanOrEqualTo(kMinSegmentGapMs));
    });

    test('не даёт метке уехать за правый край', () {
      final result = UpdateSegmentBoundaries.normalize([
        0,
        8990,
        8995,
        9000,
      ], 9000);

      expect(result[1], lessThan(result[2]));
      expect(result[2], lessThan(9000));
    });

    test('оставляет корректные границы без изменений', () {
      final input = [0, 3000, 6000, 9000];

      expect(UpdateSegmentBoundaries.normalize(input, 9000), input);
    });
  });
}

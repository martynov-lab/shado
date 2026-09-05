import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/lessons/domain/entities/audio_trim.dart';
import 'package:shado/features/lessons/domain/entities/segment_boundaries.dart';

void main() {
  const full = AudioTrim.full(9000);

  /// A trimmed track: the first and last seconds are cut off.
  const trimmed = AudioTrim(startMs: 1000, endMs: 8000);

  group('SegmentBoundaries.even', () {
    test('делит аудио поровну и встык', () {
      expect(SegmentBoundaries.even(3, full), [0, 3000, 6000, 9000]);
    });

    test('без кусков или без длительности границ нет', () {
      expect(SegmentBoundaries.even(0, full), isEmpty);
      expect(SegmentBoundaries.even(3, const AudioTrim.full(0)), isEmpty);
    });

    test('на обрезанной дорожке делит только оставленный отрезок', () {
      expect(SegmentBoundaries.even(2, trimmed), [1000, 4500, 8000]);
    });
  });

  group('SegmentBoundaries.resize', () {
    test('оставляет разметку как есть, если число кусков не изменилось', () {
      final current = [0, 1000, 7000, 9000];

      expect(SegmentBoundaries.resize(current, 3, full), current);
    });

    test('при добавлении куска сохраняет уже расставленные метки', () {
      final result = SegmentBoundaries.resize([0, 1000, 7000, 9000], 4, full);

      expect(result.take(3), [0, 1000, 7000]);
      expect(result.length, 5);
      expect(result.last, 9000);
    });

    test('при удалении куска сохраняет метки с начала', () {
      final result = SegmentBoundaries.resize([0, 1000, 7000, 9000], 2, full);

      expect(result, [0, 1000, 9000]);
    });

    test('пустую разметку раскладывает равномерно', () {
      expect(SegmentBoundaries.resize(const [], 3, full), [
        0,
        3000,
        6000,
        9000,
      ]);
    });

    test('разводит метки минимум на kMinSegmentGapMs', () {
      final result = SegmentBoundaries.resize([0, 100], 3, const AudioTrim.full(600));

      for (var i = 1; i < result.length; i++) {
        expect(result[i] - result[i - 1], greaterThanOrEqualTo(1));
      }
      expect(result.first, 0);
      expect(result.last, 600);
      expect(result[1], greaterThanOrEqualTo(kMinSegmentGapMs));
    });

    test('переносит разметку целого файла на обрезанную дорожку', () {
      // Markers outside the trim are pulled inside; the one inside stays.
      final result = SegmentBoundaries.resize(
        [0, 500, 4000, 8500, 9000],
        4,
        trimmed,
      );

      expect(result.first, 1000);
      expect(result.last, 8000);
      expect(result[2], 4000);
      for (var i = 1; i < result.length; i++) {
        expect(result[i] - result[i - 1], greaterThanOrEqualTo(kMinSegmentGapMs));
      }
    });
  });

  group('SegmentBoundaries.refit', () {
    test('метки внутри отрезка остаются на своих местах', () {
      final result = SegmentBoundaries.refit([0, 3000, 6000, 9000], trimmed);

      expect(result, [1000, 3000, 6000, 8000]);
    });

    test('обрезка хвоста не схлопывает потерявшие место метки', () {
      // Markers past the new end split the remaining space evenly.
      final result = SegmentBoundaries.refit(
        [0, 3000, 6000, 7500, 9000],
        const AudioTrim(startMs: 0, endMs: 5000),
      );

      expect(result.length, 5);
      expect(result, [0, 3000, 3666, 4333, 5000]);
    });

    test('обрезка головы не схлопывает потерявшие место метки', () {
      final result = SegmentBoundaries.refit(
        [0, 1000, 2000, 7000, 9000],
        const AudioTrim(startMs: 4000, endMs: 9000),
      );

      expect(result.length, 5);
      expect(result.first, 4000);
      expect(result.last, 9000);
      // 7000 survived while 1000 and 2000 split the head before it.
      expect(result[3], 7000);
      expect(result, [4000, 5000, 6000, 7000, 9000]);
    });

    test('куски не вырождаются, даже когда за краями осталось всё', () {
      final result = SegmentBoundaries.refit(
        [0, 1000, 2000, 3000, 9000],
        const AudioTrim(startMs: 5000, endMs: 8000),
      );

      expect(result.first, 5000);
      expect(result.last, 8000);
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i] - result[i - 1],
          greaterThanOrEqualTo(kMinSegmentGapMs),
        );
      }
    });

    test('единственный кусок занимает отрезок целиком', () {
      expect(SegmentBoundaries.refit([0, 9000], trimmed), [1000, 8000]);
    });
  });

  group('SegmentBoundaries.normalize', () {
    test('прижимает крайние границы к краям аудио', () {
      final result = SegmentBoundaries.normalize([500, 3000, 8000], full);

      expect(result.first, 0);
      expect(result.last, 9000);
    });

    test('прижимает крайние границы к краям обрезки', () {
      final result = SegmentBoundaries.normalize([0, 3000, 9000], trimmed);

      expect(result.first, 1000);
      expect(result.last, 8000);
      expect(result[1], 3000);
    });

    test('разводит соседние границы минимум на kMinSegmentGapMs', () {
      final result = SegmentBoundaries.normalize([0, 1000, 1000, 9000], full);

      expect(result[2] - result[1], greaterThanOrEqualTo(kMinSegmentGapMs));
    });

    test('не даёт метке уехать за правый край', () {
      final result = SegmentBoundaries.normalize([0, 8990, 8995, 9000], full);

      expect(result[1], lessThan(result[2]));
      expect(result[2], lessThan(9000));
    });

    test('оставляет корректные границы без изменений', () {
      final input = [0, 3000, 6000, 9000];

      expect(SegmentBoundaries.normalize(input, full), input);
    });

    test('на коротком отрезке ужимает зазор, но держит порядок', () {
      // Five 200 ms segments do not fit in 600 ms, so the gap gives way.
      final result = SegmentBoundaries.normalize(
        [0, 0, 0, 0, 0, 600],
        const AudioTrim.full(600),
      );

      expect(result.first, 0);
      expect(result.last, 600);
      for (var i = 1; i < result.length; i++) {
        expect(result[i], greaterThan(result[i - 1]));
      }
    });
  });

  group('SegmentBoundaries.insertAt', () {
    test('вставляет первую метку в позицию плеера, удлиняя разметку', () {
      final result = SegmentBoundaries.insertAt([0, 9000], 1, 2000, full);

      expect(result, [0, 2000, 9000]);
    });

    test('следующую метку ставит в позицию плеера, сохраняя прежние', () {
      final result = SegmentBoundaries.insertAt([0, 3000, 9000], 2, 6000, full);

      expect(result, [0, 3000, 6000, 9000]);
    });

    test('прижимает метку к предыдущей, если плеер раньше неё', () {
      // A new marker goes after the previous one with a gap, not before it.
      final result = SegmentBoundaries.insertAt([0, 4000, 9000], 2, 0, full);

      expect(result, [0, 4000, 4200, 9000]);
      expect(result[2] - result[1], kMinSegmentGapMs);
    });

    test('первую метку при ползунке в начале отводит от левого края', () {
      final result = SegmentBoundaries.insertAt([0, 9000], 1, 0, full);

      expect(result, [0, kMinSegmentGapMs, 9000]);
    });

    test('индекс вне диапазона ничего не меняет', () {
      const input = [0, 3000, 9000];

      expect(SegmentBoundaries.insertAt(input, 0, 1000, full), input);
      expect(SegmentBoundaries.insertAt(input, 3, 1000, full), input);
    });

    test('на обрезанной дорожке не выходит за оставленный отрезок', () {
      // The player at 500 is left of the range, so the marker keeps a gap.
      final result = SegmentBoundaries.insertAt([1000, 8000], 1, 500, trimmed);

      expect(result.first, 1000);
      expect(result.last, 8000);
      expect(result[1], greaterThanOrEqualTo(1000 + kMinSegmentGapMs));
    });
  });
}

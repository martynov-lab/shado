import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/lessons/domain/entities/audio_trim.dart';
import 'package:shado/features/lessons/domain/entities/segment_boundaries.dart';

void main() {
  const full = AudioTrim.full(9000);

  /// Обрезанная дорожка: у файла отрезаны первая и последняя секунды.
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
      // Метки 500 и 8500 остались за краями обрезки — их подтягивает внутрь,
      // а попавшая в отрезок 4000 стоит на месте.
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
      // 6000 и 7500 остались за новым концом: они делят пополам то, что
      // осталось после 3000, а не липнут к правому краю.
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
      // 7000 уцелела, а 1000 и 2000 поделили голову до неё.
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
      // Пять кусков по 200 мс в 600 мс не помещаются — зазор уступает место.
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

  group('SegmentBoundaries.placeInner', () {
    test('ставит метку в позицию плеера, а хвост делит поровну', () {
      final result = SegmentBoundaries.placeInner(
        [0, 3000, 6000, 9000],
        1,
        2000,
        full,
      );

      // Метка №1 встала в 2000, две метки справа поделили остаток поровну.
      expect(result, [0, 2000, 5500, 9000]);
    });

    test('прижимает метку к предыдущей, если плеер раньше неё', () {
      // Плеер (1000) оказался перед уже проставленной меткой №1 (4000) —
      // новая встаёт вплотную к ней, а не перескакивает через неё.
      final result = SegmentBoundaries.placeInner(
        [0, 4000, 6000, 9000],
        2,
        1000,
        full,
      );

      expect(result, [0, 4000, 4200, 9000]);
      expect(result[2] - result[1], kMinSegmentGapMs);
    });

    test('расставляет метки по очереди слева направо', () {
      var boundaries = [0, 3000, 6000, 9000];
      boundaries = SegmentBoundaries.placeInner(boundaries, 1, 2500, full);
      boundaries = SegmentBoundaries.placeInner(boundaries, 2, 5000, full);

      // Обе метки оказались там, где стоял плеер.
      expect(boundaries, [0, 2500, 5000, 9000]);
    });

    test('индекс вне диапазона внутренних меток ничего не меняет', () {
      const input = [0, 3000, 6000, 9000];

      expect(SegmentBoundaries.placeInner(input, 0, 1000, full), input);
      expect(SegmentBoundaries.placeInner(input, 3, 1000, full), input);
    });

    test('на обрезанной дорожке не выходит за оставленный отрезок', () {
      final result = SegmentBoundaries.placeInner(
        [1000, 4500, 8000],
        1,
        5000,
        trimmed,
      );

      expect(result.first, 1000);
      expect(result.last, 8000);
      expect(result[1], 5000);
    });
  });
}

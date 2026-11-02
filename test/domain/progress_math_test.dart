import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/progress_math.dart';

void main() {
  const keys = ['s:a', 's:b', 's:c'];

  group('progressIsComplete', () {
    test('complete when every item has five stars', () {
      expect(progressIsComplete({'s:a': 5, 's:b': 5, 's:c': 5}, keys), isTrue);
    });

    test('one item below five stars means not complete', () {
      expect(progressIsComplete({'s:a': 5, 's:b': 4, 's:c': 5}, keys), isFalse);
    });

    test('an unrated item counts as zero', () {
      expect(progressIsComplete({'s:a': 5, 's:b': 5}, keys), isFalse);
    });

    test('an empty lesson is not complete', () {
      expect(progressIsComplete({}, const []), isFalse);
    });

    test('ratings of items outside the lesson are ignored', () {
      expect(progressIsComplete({'s:x': 5}, const ['s:a']), isFalse);
    });
  });

  group('lessonProgressFraction', () {
    test('no ratings gives zero', () {
      expect(lessonProgressFraction({}, keys), 0);
    });

    test('every item at five stars gives one', () {
      expect(lessonProgressFraction({'s:a': 5, 's:b': 5, 's:c': 5}, keys), 1);
    });

    test('is the average rating over five', () {
      // (5 + 3 + 0) / 15.
      expect(
        lessonProgressFraction({'s:a': 5, 's:b': 3}, keys),
        closeTo(8 / 15, 1e-9),
      );
    });

    test('an empty lesson gives zero', () {
      expect(lessonProgressFraction({'s:a': 5}, const []), 0);
    });
  });
}

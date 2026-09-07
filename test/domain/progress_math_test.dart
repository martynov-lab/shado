import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/progress_math.dart';

void main() {
  group('progressIsComplete', () {
    test('complete when every segment was repeated at least the threshold', () {
      expect(progressIsComplete({0: 3, 1: 3, 2: 4}, 3, 3), isTrue);
    });

    test('one segment below the threshold means not complete', () {
      expect(progressIsComplete({0: 3, 1: 2, 2: 3}, 3, 3), isFalse);
    });

    test('a missing segment counts as zero', () {
      expect(progressIsComplete({0: 3, 1: 3}, 3, 3), isFalse);
    });

    test('an empty lesson or a zero threshold is not complete', () {
      expect(progressIsComplete({}, 0, 3), isFalse);
      expect(progressIsComplete({0: 5}, 1, 0), isFalse);
    });
  });

  group('lessonProgressFraction', () {
    test('no repeats gives zero', () {
      expect(lessonProgressFraction({}, 3, 3), 0);
    });

    test('every segment at the threshold gives one', () {
      expect(lessonProgressFraction({0: 3, 1: 3, 2: 3}, 3, 3), 1);
    });

    test('half of the work is about 0.5', () {
      // One segment done, another untouched: half of the progress.
      expect(lessonProgressFraction({0: 3, 1: 0}, 2, 3), 0.5);
    });

    test('repeats beyond the threshold never exceed 1', () {
      expect(lessonProgressFraction({0: 10, 1: 10}, 2, 3), 1);
    });
  });
}

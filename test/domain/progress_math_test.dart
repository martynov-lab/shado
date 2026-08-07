import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/progress_math.dart';

void main() {
  group('progressIsComplete', () {
    test('пройден, когда каждый сегмент повторён не меньше порога', () {
      expect(progressIsComplete({0: 3, 1: 3, 2: 4}, 3, 3), isTrue);
    });

    test('один сегмент ниже порога — не пройден', () {
      expect(progressIsComplete({0: 3, 1: 2, 2: 3}, 3, 3), isFalse);
    });

    test('отсутствующий сегмент считается нулём', () {
      expect(progressIsComplete({0: 3, 1: 3}, 3, 3), isFalse);
    });

    test('пустой урок или нулевой порог — не пройден', () {
      expect(progressIsComplete({}, 0, 3), isFalse);
      expect(progressIsComplete({0: 5}, 1, 0), isFalse);
    });
  });

  group('lessonProgressFraction', () {
    test('нет повторов — ноль', () {
      expect(lessonProgressFraction({}, 3, 3), 0);
    });

    test('все сегменты на пороге — единица', () {
      expect(lessonProgressFraction({0: 3, 1: 3, 2: 3}, 3, 3), 1);
    });

    test('половина — примерно 0.5', () {
      // Два сегмента: один пройден (3), другой наполовину (полтора от 3
      // невозможно, берём 0 и 3 → 0.5).
      expect(lessonProgressFraction({0: 3, 1: 0}, 2, 3), 0.5);
    });

    test('повторы сверх порога не дают больше 1', () {
      expect(lessonProgressFraction({0: 10, 1: 10}, 2, 3), 1);
    });
  });
}

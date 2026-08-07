import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/domain/progress_streak.dart';

ProgressDay _day(String day) =>
    ProgressDay(day: day, listenedMs: 60000, segmentRepeats: 1);

ProgressDay _inactive(String day) =>
    ProgressDay(day: day, listenedMs: 0, segmentRepeats: 0);

void main() {
  group('currentStreak', () {
    test('пустая история — ноль', () {
      expect(currentStreak(const []), 0);
    });

    test('один активный день — единица', () {
      expect(currentStreak([_day('2026-08-06')]), 1);
    });

    test('подряд идущие активные дни складываются', () {
      expect(
        currentStreak([
          _day('2026-08-04'),
          _day('2026-08-05'),
          _day('2026-08-06'),
        ]),
        3,
      );
    });

    test('разрыв в календаре обрывает серию на свежем участке', () {
      expect(
        currentStreak([
          _day('2026-08-01'),
          _day('2026-08-02'),
          _day('2026-08-05'),
          _day('2026-08-06'),
        ]),
        2,
      );
    });

    test('дни без активности не в счёт', () {
      expect(
        currentStreak([
          _inactive('2026-08-05'),
          _day('2026-08-06'),
        ]),
        1,
      );
    });
  });
}

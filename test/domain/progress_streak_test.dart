import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/domain/progress_streak.dart';

ProgressDay _day(String day) =>
    ProgressDay(day: day, listenedMs: 60000, segmentRepeats: 1);

ProgressDay _inactive(String day) =>
    ProgressDay(day: day, listenedMs: 0, segmentRepeats: 0);

void main() {
  group('currentStreak', () {
    test('an empty history gives zero', () {
      expect(currentStreak(const []), 0);
    });

    test('a single active day gives one', () {
      expect(currentStreak([_day('2026-08-06')]), 1);
    });

    test('consecutive active days add up', () {
      expect(
        currentStreak([
          _day('2026-08-04'),
          _day('2026-08-05'),
          _day('2026-08-06'),
        ]),
        3,
      );
    });

    test('a gap in the calendar cuts the streak at the recent stretch', () {
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

    test('days without activity do not count', () {
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

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/domain/progress_week.dart';

ProgressDay _day(String day, int minutes) =>
    ProgressDay(day: day, listenedMs: minutes * 60000, segmentRepeats: 0);

void main() {
  group('weekWithGaps', () {
    test('всегда ровно семь дней, оканчивающихся сегодняшним', () {
      final week = weekWithGaps(const [], '2026-08-08');

      expect(week.length, 7);
      expect(week.first.day, '2026-08-02');
      expect(week.last.day, '2026-08-08');
    });

    test('пропущенные сервером дни заполняются нулями', () {
      final week = weekWithGaps([
        _day('2026-08-04', 5),
        _day('2026-08-08', 12),
      ], '2026-08-08');

      expect([for (final d in week) d.listenedMinutes], [0, 0, 5, 0, 0, 0, 12]);
    });

    test('данные присланных дней сохраняются на своих датах', () {
      final week = weekWithGaps([_day('2026-08-06', 7)], '2026-08-08');
      final wednesday = week.firstWhere((d) => d.day == '2026-08-06');

      expect(wednesday.listenedMinutes, 7);
    });

    test('дни за пределами окна отбрасываются', () {
      final week = weekWithGaps([_day('2026-07-30', 99)], '2026-08-08');

      expect(week.every((d) => d.listenedMinutes == 0), isTrue);
    });

    test('без даты сегодня окно строится от текущего дня', () {
      final week = weekWithGaps(const [], '');

      expect(week.length, 7);
      final today = DateTime.now();
      final expected =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      expect(week.last.day, expected);
    });
  });
}

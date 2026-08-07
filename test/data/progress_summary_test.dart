import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';

void main() {
  group('ProgressSummary.fromJson', () {
    test('читает сводку целиком', () {
      final summary = ProgressSummary.fromJson({
        'today': {
          'day': '2026-08-06',
          'listened_ms': 180000,
          'segment_repeats': 10,
        },
        'totals': {
          'listened_ms': 360000,
          'segment_repeats': 20,
          'lessons_completed': 2,
        },
        'week_minutes': 6,
        'week': [
          {'day': '2026-08-06', 'listened_ms': 180000, 'segment_repeats': 10},
        ],
        'recent_lesson_ids': ['a', 'b'],
        'daily_goal_minutes': 20,
        'completion_reps': 10,
      });

      expect(summary.today.listenedMinutes, 3);
      expect(summary.totals.lessonsCompleted, 2);
      expect(summary.weekMinutes, 6);
      expect(summary.week, hasLength(1));
      expect(summary.recentLessonIds, ['a', 'b']);
      expect(summary.dailyGoalMinutes, 20);
      expect(summary.completionReps, 10);
    });

    test('отсутствующие поля — безопасные значения по умолчанию', () {
      final summary = ProgressSummary.fromJson(const {});

      expect(summary.today.listenedMs, 0);
      expect(summary.totals.segmentRepeats, 0);
      expect(summary.week, isEmpty);
      expect(summary.recentLessonIds, isEmpty);
      expect(summary.dailyGoalMinutes, isNull);
      // Порог по умолчанию не ноль, чтобы прогресс-бар не делил на ноль.
      expect(summary.completionReps, greaterThan(0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';

void main() {
  group('ProgressSummary.fromJson', () {
    test('reads the whole summary', () {
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
      });

      expect(summary.today.listenedMinutes, 3);
      expect(summary.totals.lessonsCompleted, 2);
      expect(summary.weekMinutes, 6);
      expect(summary.week, hasLength(1));
      expect(summary.recentLessonIds, ['a', 'b']);
      expect(summary.dailyGoalMinutes, 20);
    });

    test('reads learned phrases in totals, today and the week', () {
      final summary = ProgressSummary.fromJson({
        'today': {'day': '2026-11-02', 'phrases_learned': 2},
        'totals': {'phrases_learned': 7},
        'week': [
          {'day': '2026-11-02', 'phrases_learned': 2},
        ],
      });

      expect(summary.totals.phrasesLearned, 7);
      expect(summary.today.phrasesLearned, 2);
      expect(summary.week.single.phrasesLearned, 2);
    });

    test('missing fields fall back to safe defaults', () {
      final summary = ProgressSummary.fromJson(const {});

      expect(summary.today.listenedMs, 0);
      expect(summary.totals.segmentRepeats, 0);
      expect(summary.week, isEmpty);
      expect(summary.recentLessonIds, isEmpty);
      expect(summary.dailyGoalMinutes, isNull);
      expect(summary.totals.phrasesLearned, 0);
    });
  });
}

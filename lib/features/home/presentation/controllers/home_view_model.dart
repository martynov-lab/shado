import '../../../progress/domain/entities/progress_summary.dart';
import '../../../progress/domain/progress_streak.dart';
import '../../../progress/domain/progress_week.dart';

/// Home screen data computed from the progress summary and activity history.
class HomeViewModel {
  const HomeViewModel({
    required this.stats,
    required this.statsCompact,
    required this.streakDays,
    required this.weekDays,
    required this.weekDone,
    required this.weekTodayIndex,
    required this.weekMinutes,
    required this.goalRatio,
    required this.goalValue,
    required this.goalRemaining,
    required this.recentLessonIds,
  });

  factory HomeViewModel.from(
    ProgressSummary? summary,
    List<ProgressDay> history,
  ) {
    final today =
        summary?.today ??
        const ProgressDay(day: '', listenedMs: 0, segmentRepeats: 0);
    final totals =
        summary?.totals ??
        const ProgressTotals(
          listenedMs: 0,
          segmentRepeats: 0,
          lessonsCompleted: 0,
        );
    final week = summary?.week ?? const <ProgressDay>[];
    final dailyGoal = summary?.dailyGoalMinutes ?? 0;
    final weekTotal = summary?.weekMinutes ?? 0;

    final streak = currentStreak(history);

    // Stat tiles: minutes today, the day streak and repeats.
    final todayMinutes = today.listenedMinutes;
    final toGoal = dailyGoal - todayMinutes;
    final todayDelta = dailyGoal <= 0
        ? 'за сегодня'
        : (toGoal > 0 ? 'до цели $toGoal мин' : 'цель дня выполнена');
    final todayStat = ('Сегодня', '$todayMinutes', 'мин', todayDelta);
    final streakStat = (
      'Серия',
      '$streak',
      'дн',
      streak > 0 ? 'серия идёт' : 'начни серию',
    );
    final repeatsStat = (
      'Повторов',
      '${today.segmentRepeats}',
      null,
      'всего ${totals.segmentRepeats}',
    );

    // The week: the last seven days from the server.
    final (weekDays, weekDone, weekMinutes, weekTodayIndex) = _week(week, today);

    // The weekly goal is the daily one times seven.
    final weekGoal = dailyGoal * 7;
    final goalRatio = weekGoal <= 0
        ? 0.0
        : (weekTotal / weekGoal).clamp(0, 1).toDouble();
    final remaining = weekGoal - weekTotal;
    final goalValue = weekGoal <= 0
        ? '$weekTotal мин'
        : '$weekTotal / $weekGoal мин';
    final goalRemaining = weekGoal <= 0
        ? 'Цель не задана'
        : (remaining > 0 ? 'осталось $remaining мин' : 'цель выполнена');

    return HomeViewModel(
      stats: [todayStat, streakStat, repeatsStat],
      statsCompact: [todayStat, repeatsStat],
      streakDays: streak,
      weekDays: weekDays,
      weekDone: weekDone,
      weekTodayIndex: weekTodayIndex,
      weekMinutes: weekMinutes,
      goalRatio: goalRatio,
      goalValue: goalValue,
      goalRemaining: goalRemaining,
      recentLessonIds: summary?.recentLessonIds ?? const <String>[],
    );
  }

  /// Stat tiles: label, value, optional unit and a hint.
  final List<(String, String, String?, String)> stats;

  /// Two tiles for the narrow layout: today and repeats.
  final List<(String, String, String?, String)> statsCompact;

  final int streakDays;

  /// Practice week: day labels, activity flags and the index of today.
  final List<String> weekDays;
  final List<bool> weekDone;
  final int weekTodayIndex;

  /// Daily minutes as a percentage of the weekly maximum.
  final List<int> weekMinutes;

  final double goalRatio;
  final String goalValue;
  final String goalRemaining;

  /// Lessons the user worked on most recently.
  final List<String> recentLessonIds;

  static const List<String> _weekdays = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  /// Maps a week onto widget inputs, padding missing days with zeros.
  static (List<String>, List<bool>, List<int>, int) _week(
    List<ProgressDay> week,
    ProgressDay today,
  ) {
    final days = weekWithGaps(week, today.day);
    final labels = [for (final day in days) _weekdayLabel(day.day)];
    final done = [
      for (final day in days) day.listenedMs > 0 || day.segmentRepeats > 0,
    ];
    final minutes = [for (final day in days) day.listenedMinutes];
    final maxMinutes = minutes.fold<int>(0, (a, b) => b > a ? b : a);
    final bars = [
      for (final m in minutes)
        maxMinutes <= 0 ? 0 : (m * 100 / maxMinutes).round(),
    ];
    var todayIndex = days.indexWhere((day) => day.day == today.day);
    if (todayIndex < 0) todayIndex = days.length - 1;
    return (labels, done, bars, todayIndex);
  }

  static String _weekdayLabel(String day) {
    final date = DateTime.tryParse(day);
    if (date == null) return '';
    return _weekdays[(date.weekday - 1).clamp(0, 6)];
  }
}

import '../../../lessons/domain/entities/lesson.dart';
import '../../../progress/domain/entities/progress_summary.dart';
import '../../../progress/domain/progress_streak.dart';
import '../../../progress/domain/progress_week.dart';
import 'home_lesson_tile.dart';

/// Home screen data ready for the widgets: greeting, stats, the week and the
/// lessons to show.
class HomeOverview {
  const HomeOverview({
    required this.greetingName,
    required this.lessons,
    required this.lessonsCount,
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
  });

  /// [summary] is `null` while it loads; the screen then shows zeros.
  factory HomeOverview.from({
    required ProgressSummary? summary,
    required List<ProgressDay> history,
    required String email,
    required List<Lesson> catalog,
  }) {
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
        ? 'today'
        : (toGoal > 0 ? '$toGoal min to goal' : 'daily goal reached');
    final todayStat = ('Today', '$todayMinutes', 'min', todayDelta);
    final streakStat = (
      'Streak',
      '$streak',
      'd',
      streak > 0 ? 'streak is on' : 'start a streak',
    );
    final repeatsStat = (
      'Repeats',
      '${today.segmentRepeats}',
      null,
      '${totals.segmentRepeats} total',
    );

    // The week: the last seven days from the server.
    final (weekDays, weekDone, weekMinutes, weekTodayIndex) = _week(
      week,
      today,
    );

    // The weekly goal is the daily one times seven.
    final weekGoal = dailyGoal * 7;
    final goalRatio = weekGoal <= 0
        ? 0.0
        : (weekTotal / weekGoal).clamp(0, 1).toDouble();
    final remaining = weekGoal - weekTotal;
    final goalValue = weekGoal <= 0
        ? '$weekTotal min'
        : '$weekTotal / $weekGoal min';
    final goalRemaining = weekGoal <= 0
        ? 'No goal set'
        : (remaining > 0 ? '$remaining min left' : 'goal reached');

    return HomeOverview(
      greetingName: _greetingName(email),
      lessons: _previewLessons(
        summary?.recentLessonIds ?? const <String>[],
        catalog,
      ),
      lessonsCount: catalog.length,
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
    );
  }

  /// Capitalized part of the email before `@`.
  final String greetingName;

  /// Up to five lessons: the recent ones, or the start of the catalog.
  final List<HomeLessonTile> lessons;

  final int lessonsCount;

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

  static const List<String> _weekdays = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
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

  static List<HomeLessonTile> _previewLessons(
    List<String> recentIds,
    List<Lesson> catalog,
  ) {
    final byId = {for (final lesson in catalog) lesson.id: lesson};
    final recent = <Lesson>[for (final id in recentIds) ?byId[id]];
    final source = recent.isNotEmpty ? recent : catalog;
    return [for (final lesson in source.take(5)) HomeLessonTile.from(lesson)];
  }

  static String _greetingName(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'friend';
    return local[0].toUpperCase() + local.substring(1);
  }

  static String _weekdayLabel(String day) {
    final date = DateTime.tryParse(day);
    if (date == null) return '';
    return _weekdays[(date.weekday - 1).clamp(0, 6)];
  }
}

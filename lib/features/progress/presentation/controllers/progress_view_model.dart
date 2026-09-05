import '../../domain/entities/progress_summary.dart';
import '../../domain/progress_streak.dart';
import '../../domain/progress_week.dart';

/// Progress screen data mapped onto widget inputs.
class ProgressViewModel {
  const ProgressViewModel({
    required this.stats,
    required this.statsWide,
    required this.weekBars,
    required this.weekLabels,
    required this.weekTodayIndex,
    required this.heatmapCells,
    required this.streakDays,
    required this.streakHint,
    required this.streakHintShort,
    required this.goalRatio,
    required this.goalValue,
    required this.goalRemaining,
    required this.recentLessonIds,
  });

  factory ProgressViewModel.from(
    ProgressSummary summary,
    List<ProgressDay> history,
  ) {
    final today = summary.today;
    final totals = summary.totals;
    // A full week: the server omits idle days, so pad them with zeros.
    final week = weekWithGaps(summary.week, today.day);

    // Chart bars are daily minutes as a percentage of the maximum.
    final weekMinutes = [for (final day in week) day.listenedMinutes];
    final maxMinutes = weekMinutes.fold<int>(0, (a, b) => b > a ? b : a);
    final bars = [
      for (final minutes in weekMinutes)
        maxMinutes <= 0 ? 0 : (minutes * 100 / maxMinutes).round(),
    ];
    final labels = [for (final day in week) _weekdayLabel(day.day)];
    var todayIndex = week.indexWhere((day) => day.day == today.day);
    if (todayIndex < 0) todayIndex = week.isEmpty ? 0 : week.length - 1;

    // The weekly goal is the daily one times seven.
    final dailyGoal = summary.dailyGoalMinutes ?? 0;
    final weekGoal = dailyGoal * 7;
    final double goalRatio = weekGoal <= 0
        ? 0
        : (summary.weekMinutes / weekGoal).clamp(0, 1).toDouble();
    final goalValue = weekGoal <= 0
        ? '${summary.weekMinutes} мин'
        : '${summary.weekMinutes} / $weekGoal мин';
    final remaining = weekGoal - summary.weekMinutes;
    final goalRemaining = weekGoal <= 0
        ? 'Цель не задана'
        : (remaining > 0 ? 'осталось $remaining мин' : 'цель выполнена');

    final streak = currentStreak(history);
    final streakHint = streak > 0
        ? 'Не прерывай серию — позанимайся сегодня!'
        : 'Начни серию: позанимайся сегодня';
    final streakHintShort = streak > 0 ? 'Серия идёт' : 'Начни серию';

    final avgPerDay = summary.weekMinutes ~/ 7;
    final stats = <(String, String, String?, String)>[
      ('За неделю', '${summary.weekMinutes}', 'мин', 'сегодня ${today.listenedMinutes}'),
      ('Повторов', '${totals.segmentRepeats}', null, 'всего'),
      ('Уроков', '${totals.lessonsCompleted}', null, 'пройдено'),
    ];
    final statsWide = <(String, String, String?, String)>[
      ...stats,
      ('Ср. в день', '$avgPerDay', 'мин', dailyGoal > 0 ? 'цель $dailyGoal' : ''),
    ];

    return ProgressViewModel(
      stats: stats,
      statsWide: statsWide,
      weekBars: bars,
      weekLabels: labels,
      weekTodayIndex: todayIndex,
      heatmapCells: _heatmapCells(history),
      streakDays: streak,
      streakHint: streakHint,
      streakHintShort: streakHintShort,
      goalRatio: goalRatio,
      goalValue: goalValue,
      goalRemaining: goalRemaining,
      recentLessonIds: summary.recentLessonIds,
    );
  }

  final List<(String, String, String?, String)> stats;
  final List<(String, String, String?, String)> statsWide;

  /// Bar heights in percent and the day labels.
  final List<int> weekBars;
  final List<String> weekLabels;
  final int weekTodayIndex;

  /// Daily minutes for the heatmap, oldest to newest.
  final List<int> heatmapCells;

  final int streakDays;
  final String streakHint;
  final String streakHintShort;

  final double goalRatio;
  final String goalValue;
  final String goalRemaining;

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

  static String _weekdayLabel(String day) {
    final date = DateTime.tryParse(day);
    if (date == null) return '';
    return _weekdays[(date.weekday - 1).clamp(0, 6)];
  }

  /// The 70 heatmap cells; missing days are zeros.
  static List<int> _heatmapCells(List<ProgressDay> history) {
    const size = 70;
    final sorted = [...history]..sort((a, b) => a.day.compareTo(b.day));
    final recent = sorted.length > size
        ? sorted.sublist(sorted.length - size)
        : sorted;
    final minutes = [for (final day in recent) day.listenedMinutes];
    // Pad with zeros at the front so recent days land at the end.
    return [
      ...List<int>.filled(size - minutes.length, 0),
      ...minutes,
    ];
  }
}

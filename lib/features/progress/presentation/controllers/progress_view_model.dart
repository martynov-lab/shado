import '../../domain/entities/progress_summary.dart';
import '../../domain/progress_streak.dart';
import '../../domain/progress_week.dart';

/// Готовые к отрисовке данные экрана прогресса: сводка сервера и история,
/// приведённые к входам виджетов из макета.
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
    // Полная неделя: дни без занятий сервер опускает, дополняем их нулями.
    final week = weekWithGaps(summary.week, today.day);

    // Столбцы графика — минуты по дням, в процентах от максимума за неделю.
    final weekMinutes = [for (final day in week) day.listenedMinutes];
    final maxMinutes = weekMinutes.fold<int>(0, (a, b) => b > a ? b : a);
    final bars = [
      for (final minutes in weekMinutes)
        maxMinutes <= 0 ? 0 : (minutes * 100 / maxMinutes).round(),
    ];
    final labels = [for (final day in week) _weekdayLabel(day.day)];
    var todayIndex = week.indexWhere((day) => day.day == today.day);
    if (todayIndex < 0) todayIndex = week.isEmpty ? 0 : week.length - 1;

    // Дневная цель × 7 — недельная. Показываем «сделано / цель».
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

  /// Высоты столбцов графика в процентах и подписи дней.
  final List<int> weekBars;
  final List<String> weekLabels;
  final int weekTodayIndex;

  /// Минуты по дням для тепловой карты (70 ячеек, старые → свежие).
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

  /// 70 ячеек тепловой карты: минуты за последние 70 дней в хронологическом
  /// порядке, недостающие дни — нули.
  static List<int> _heatmapCells(List<ProgressDay> history) {
    const size = 70;
    final sorted = [...history]..sort((a, b) => a.day.compareTo(b.day));
    final recent = sorted.length > size
        ? sorted.sublist(sorted.length - size)
        : sorted;
    final minutes = [for (final day in recent) day.listenedMinutes];
    // Дополняем спереди нулями, чтобы свежие дни оказались в конце сетки.
    return [
      ...List<int>.filled(size - minutes.length, 0),
      ...minutes,
    ];
  }
}

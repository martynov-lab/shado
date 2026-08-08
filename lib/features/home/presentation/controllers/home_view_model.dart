import '../../../progress/domain/entities/progress_summary.dart';
import '../../../progress/domain/progress_streak.dart';
import '../../../progress/domain/progress_week.dart';

/// Данные главного экрана, приведённые к входам виджетов.
///
/// Считаются из сводки прогресса (`GET /v1/progress`) и истории активности —
/// тех же данных, что показывает экран «Прогресс», — чтобы цифры на экранах не
/// расходились. Сводка может быть ещё не загружена ([summary] == null): тогда
/// показываем нули, а не блокируем экран спиннером.
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

    // «Сегодня» и «Повторов» — про сегодняшний день; «Серия» — про
    // непрерывность занятий. Дельта под числом всегда позитивная подсказка.
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

    // Неделя: последние 7 дней с сервера (как на графике прогресса).
    final (weekDays, weekDone, weekMinutes, weekTodayIndex) = _week(week, today);

    // Недельная цель — дневная × 7; показываем «сделано / цель» и остаток.
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

  /// Плитки статистики: подпись, число, единица (или `null`), подсказка.
  final List<(String, String, String?, String)> stats;

  /// Две плитки рядом с «героем» на десктопе: «Сегодня» и «Повторов».
  final List<(String, String, String?, String)> statsCompact;

  final int streakDays;

  /// Неделя занятий: подписи дней, отметка активности и индекс сегодня.
  final List<String> weekDays;
  final List<bool> weekDone;
  final int weekTodayIndex;

  /// Минуты по дням в процентах от максимума за неделю — под высоту столбца.
  final List<int> weekMinutes;

  final double goalRatio;
  final String goalValue;
  final String goalRemaining;

  /// Последние уроки, с которыми работал пользователь (`recent_lesson_ids`).
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

  /// Раскладывает неделю по входам виджетов. Дни без занятий сервер опускает —
  /// дополняем их нулями, чтобы «Эта неделя» всегда показывала все семь дней, а
  /// пока сводки нет — пустую неделю, оканчивающуюся сегодня.
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

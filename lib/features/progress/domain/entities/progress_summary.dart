/// День активности: минуты и повторы за календарный день (UTC) сервера.
class ProgressDay {
  const ProgressDay({
    required this.day,
    required this.listenedMs,
    required this.segmentRepeats,
  });

  factory ProgressDay.fromJson(Map<String, dynamic> json) => ProgressDay(
    day: json['day'] as String? ?? '',
    listenedMs: (json['listened_ms'] as num?)?.toInt() ?? 0,
    segmentRepeats: (json['segment_repeats'] as num?)?.toInt() ?? 0,
  );

  /// Дата в формате `YYYY-MM-DD`.
  final String day;
  final int listenedMs;
  final int segmentRepeats;

  int get listenedMinutes => listenedMs ~/ 60000;
}

/// Итоги за всё время.
class ProgressTotals {
  const ProgressTotals({
    required this.listenedMs,
    required this.segmentRepeats,
    required this.lessonsCompleted,
  });

  factory ProgressTotals.fromJson(Map<String, dynamic> json) => ProgressTotals(
    listenedMs: (json['listened_ms'] as num?)?.toInt() ?? 0,
    segmentRepeats: (json['segment_repeats'] as num?)?.toInt() ?? 0,
    lessonsCompleted: (json['lessons_completed'] as num?)?.toInt() ?? 0,
  );

  final int listenedMs;
  final int segmentRepeats;
  final int lessonsCompleted;

  int get listenedMinutes => listenedMs ~/ 60000;
}

/// Сводка прогресса (`GET /v1/progress` и ответ `POST /v1/progress/events`).
class ProgressSummary {
  const ProgressSummary({
    required this.today,
    required this.totals,
    required this.weekMinutes,
    required this.week,
    required this.recentLessonIds,
    required this.completionReps,
    this.dailyGoalMinutes,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) =>
      ProgressSummary(
        today: json['today'] is Map
            ? ProgressDay.fromJson(
                Map<String, dynamic>.from(json['today'] as Map),
              )
            : const ProgressDay(day: '', listenedMs: 0, segmentRepeats: 0),
        totals: json['totals'] is Map
            ? ProgressTotals.fromJson(
                Map<String, dynamic>.from(json['totals'] as Map),
              )
            : const ProgressTotals(
                listenedMs: 0,
                segmentRepeats: 0,
                lessonsCompleted: 0,
              ),
        weekMinutes: (json['week_minutes'] as num?)?.toInt() ?? 0,
        week: [
          for (final day in (json['week'] as List<dynamic>? ?? const []))
            ProgressDay.fromJson(Map<String, dynamic>.from(day as Map)),
        ],
        recentLessonIds: [
          for (final id in (json['recent_lesson_ids'] as List<dynamic>? ??
              const []))
            id as String,
        ],
        dailyGoalMinutes: (json['daily_goal_minutes'] as num?)?.toInt(),
        // Порог пройденности (§12.3); дублирует `GET /v1/settings`.
        completionReps: (json['completion_reps'] as num?)?.toInt() ?? 1,
      );

  final ProgressDay today;
  final ProgressTotals totals;

  /// Сумма минут за `week` — сервер считает её сам.
  final int weekMinutes;

  /// Последние 7 дней для графика динамики.
  final List<ProgressDay> week;

  /// «Последние 5» уроков (`recent_lesson_ids`) для блока «Продолжить».
  final List<String> recentLessonIds;

  /// Сколько раз повторить каждый сегмент, чтобы урок считался пройденным.
  final int completionReps;

  /// Дневная цель из профиля; `null` — не задана.
  final int? dailyGoalMinutes;
}

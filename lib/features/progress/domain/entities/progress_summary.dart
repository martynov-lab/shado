/// Activity day: minutes and repeats for one server UTC day.
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

  /// Date in `YYYY-MM-DD` format.
  final String day;
  final int listenedMs;
  final int segmentRepeats;

  int get listenedMinutes => listenedMs ~/ 60000;
}

/// All-time totals.
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

/// Progress summary from `GET /v1/progress` and event responses.
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
        // Completion threshold; mirrors `GET /v1/settings`.
        completionReps: (json['completion_reps'] as num?)?.toInt() ?? 1,
      );

  final ProgressDay today;
  final ProgressTotals totals;

  /// Total minutes for `week`, computed by the server.
  final int weekMinutes;

  /// The last seven days for the trend chart.
  final List<ProgressDay> week;

  /// The five most recent lessons for the continue block.
  final List<String> recentLessonIds;

  /// How many repeats per segment mark a lesson as done.
  final int completionReps;

  /// Daily goal from the profile; `null` when unset.
  final int? dailyGoalMinutes;
}

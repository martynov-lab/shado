/// Activity day: minutes, repeats and learned phrases for one server UTC day.
class ProgressDay {
  const ProgressDay({
    required this.day,
    required this.listenedMs,
    required this.segmentRepeats,
    this.phrasesLearned = 0,
  });

  factory ProgressDay.fromJson(Map<String, dynamic> json) => ProgressDay(
    day: json['day'] as String? ?? '',
    listenedMs: (json['listened_ms'] as num?)?.toInt() ?? 0,
    segmentRepeats: (json['segment_repeats'] as num?)?.toInt() ?? 0,
    phrasesLearned: (json['phrases_learned'] as num?)?.toInt() ?? 0,
  );

  /// Date in `YYYY-MM-DD` format.
  final String day;
  final int listenedMs;
  final int segmentRepeats;

  /// Phrases that first reached five stars on this day.
  final int phrasesLearned;

  Map<String, dynamic> toJson() => {
    'day': day,
    'listened_ms': listenedMs,
    'segment_repeats': segmentRepeats,
    'phrases_learned': phrasesLearned,
  };

  int get listenedMinutes => listenedMs ~/ 60000;
}

/// All-time totals.
class ProgressTotals {
  const ProgressTotals({
    required this.listenedMs,
    required this.segmentRepeats,
    required this.lessonsCompleted,
    this.phrasesLearned = 0,
  });

  factory ProgressTotals.fromJson(Map<String, dynamic> json) => ProgressTotals(
    listenedMs: (json['listened_ms'] as num?)?.toInt() ?? 0,
    segmentRepeats: (json['segment_repeats'] as num?)?.toInt() ?? 0,
    lessonsCompleted: (json['lessons_completed'] as num?)?.toInt() ?? 0,
    phrasesLearned: (json['phrases_learned'] as num?)?.toInt() ?? 0,
  );

  final int listenedMs;
  final int segmentRepeats;
  final int lessonsCompleted;

  /// Items currently rated with five stars.
  final int phrasesLearned;

  Map<String, dynamic> toJson() => {
    'listened_ms': listenedMs,
    'segment_repeats': segmentRepeats,
    'lessons_completed': lessonsCompleted,
    'phrases_learned': phrasesLearned,
  };

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
      );

  final ProgressDay today;
  final ProgressTotals totals;

  /// Total minutes for `week`, computed by the server.
  final int weekMinutes;

  /// The last seven days for the trend chart.
  final List<ProgressDay> week;

  /// The five most recent lessons for the continue block.
  final List<String> recentLessonIds;

  /// Daily goal from the profile; `null` when unset.
  final int? dailyGoalMinutes;

  /// The server JSON shape, readable back by [ProgressSummary.fromJson].
  Map<String, dynamic> toJson() => {
    'today': today.toJson(),
    'totals': totals.toJson(),
    'week_minutes': weekMinutes,
    'week': [for (final day in week) day.toJson()],
    'recent_lesson_ids': recentLessonIds,
    'daily_goal_minutes': ?dailyGoalMinutes,
  };
}

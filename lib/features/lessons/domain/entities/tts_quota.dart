/// Remaining free AI voice-over quota.
class TtsQuota {
  const TtsQuota({
    required this.provider,
    required this.day,
    required this.minute,
    this.userDay,
  });

  factory TtsQuota.fromJson(Map<String, dynamic> json) => TtsQuota(
    provider: json['provider'] as String? ?? '',
    day: TtsQuotaWindow.fromJson(
      json['day'] as Map<String, dynamic>? ?? const {},
    ),
    minute: TtsQuotaWindow.fromJson(
      json['minute'] as Map<String, dynamic>? ?? const {},
    ),
    userDay: json['user_day'] is Map
        ? TtsQuotaWindow.fromJson(
            Map<String, dynamic>.from(json['user_day'] as Map),
          )
        : null,
  );

  /// Which provider does the synthesis.
  final String provider;

  /// The daily quota window.
  final TtsQuotaWindow day;

  /// The per-minute quota window.
  final TtsQuotaWindow minute;

  /// The user's own daily batches; `null` from an older server.
  final TtsQuotaWindow? userDay;

  /// Voice-overs the user can still start today; `null` when unlimited.
  int? get remainingToday {
    final own = userDay;
    final values = [
      if (!day.isUnlimited) day.remaining ?? 0,
      if (own != null && !own.isUnlimited) own.remaining ?? 0,
    ];
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }
}

/// One quota window: used, limit and remaining.
class TtsQuotaWindow {
  const TtsQuotaWindow({
    required this.used,
    required this.limit,
    this.remaining,
  });

  factory TtsQuotaWindow.fromJson(Map<String, dynamic> json) => TtsQuotaWindow(
    used: (json['used'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt(),
  );

  final int used;

  /// Request limit; `0` means unlimited.
  final int limit;

  /// Remaining count; `null` when [isUnlimited].
  final int? remaining;

  bool get isUnlimited => limit == 0;
}

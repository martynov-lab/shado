/// Остаток бесплатного лимита озвучки через ИИ (`GET /v1/tts/quota`,
/// TTS_CLIENT_SPEC §4.1).
///
/// Лимитов у Gemini TTS два — на минуту и на сутки, — поэтому отказ (`429
/// tts_quota_exceeded`) бывает и временным, и дневным. Клиенту квота нужна лишь
/// как подсказка у кнопки: сколько озвучек осталось на сегодня.
class TtsQuota {
  const TtsQuota({
    required this.provider,
    required this.day,
    required this.minute,
  });

  factory TtsQuota.fromJson(Map<String, dynamic> json) => TtsQuota(
    provider: json['provider'] as String? ?? '',
    day: TtsQuotaWindow.fromJson(
      json['day'] as Map<String, dynamic>? ?? const {},
    ),
    minute: TtsQuotaWindow.fromJson(
      json['minute'] as Map<String, dynamic>? ?? const {},
    ),
  );

  /// Кто озвучивает — сейчас `gemini`. На поведение клиента не влияет.
  final String provider;

  /// Суточное окно — его остаток показываем рядом с кнопкой.
  final TtsQuotaWindow day;

  /// Минутное окно — из-за него отказ бывает временным («подождите минуту»).
  final TtsQuotaWindow minute;
}

/// Одно окно лимита: сколько использовано, каков предел и сколько осталось.
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

  /// `0` — «без ограничения»; в этом случае [remaining] сервер не присылает.
  final int limit;

  /// Остаток; `null` при [isUnlimited].
  final int? remaining;

  bool get isUnlimited => limit == 0;
}

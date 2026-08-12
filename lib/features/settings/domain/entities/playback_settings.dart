import '../../../../core/constants/app_constants.dart';

/// Настройки воспроизведения урока: применяются плеером и хранятся локально,
/// поэтому переживают перезапуск.
///
/// [defaultSpeed] задаёт стартовую скорость урока, [repeatsInCycle] — сколько
/// раз проигрывать отрезок при включённом повторе (0 — бесконечно),
/// [pauseBetweenRepeats] вставляет паузу в 1 секунду между повторами, а
/// [countdownEnabled] показывает отсчёт «3-2-1» перед стартом.
class PlaybackSettings {
  const PlaybackSettings({
    this.defaultSpeed = kNormalSpeed,
    this.repeatsInCycle = kDefaultRepeatsInCycle,
    this.pauseBetweenRepeats = true,
    this.countdownEnabled = false,
  });

  final double defaultSpeed;
  final int repeatsInCycle;
  final bool pauseBetweenRepeats;
  final bool countdownEnabled;

  PlaybackSettings copyWith({
    double? defaultSpeed,
    int? repeatsInCycle,
    bool? pauseBetweenRepeats,
    bool? countdownEnabled,
  }) {
    return PlaybackSettings(
      defaultSpeed: defaultSpeed ?? this.defaultSpeed,
      repeatsInCycle: repeatsInCycle ?? this.repeatsInCycle,
      pauseBetweenRepeats: pauseBetweenRepeats ?? this.pauseBetweenRepeats,
      countdownEnabled: countdownEnabled ?? this.countdownEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlaybackSettings &&
      other.defaultSpeed == defaultSpeed &&
      other.repeatsInCycle == repeatsInCycle &&
      other.pauseBetweenRepeats == pauseBetweenRepeats &&
      other.countdownEnabled == countdownEnabled;

  @override
  int get hashCode => Object.hash(
    defaultSpeed,
    repeatsInCycle,
    pauseBetweenRepeats,
    countdownEnabled,
  );
}

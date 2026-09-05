import '../../../../core/constants/app_constants.dart';

/// Lesson playback settings: speed, repeat count, pause between repeats and
/// the countdown.
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

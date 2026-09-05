/// Segment delimiter the user places by hand.
const String kSegmentDelimiter = '|';

/// Minimum segment duration.
const int kMinSegmentGapMs = 200;

/// Minimum duration of the range left after trimming.
const int kMinTrimMs = 500;

/// Lesson playback speeds.
const double kNormalSpeed = 1.0;
const double kSlowSpeed = 0.75;

/// Speeds offered by the default-speed setting.
const List<double> kPlaybackSpeeds = [0.5, 0.6, 0.75, 0.9, 1.0, 1.25, 1.5];

/// Speed label for the UI, such as `1.0x`.
String speedLabel(double speed) => '$speed×';

/// Repeat count of a range in a cycle: scale bounds and the default value.
/// [kInfiniteRepeats] (0) means an endless repeat.
const int kInfiniteRepeats = 0;
const int kMinRepeatsInCycle = kInfiniteRepeats;
const int kMaxRepeatsInCycle = 10;
const int kDefaultRepeatsInCycle = 3;

/// Repeat count label for the UI — «∞» or the number itself.
String repeatsLabel(int repeats) =>
    repeats == kInfiniteRepeats ? '∞' : '$repeats';

/// Number of bars the waveform peaks are downsampled to before painting.
const int kWaveformResolution = 2000;

/// Text length limit for AI voice-over.
const int kMaxTtsChars = 2000;

/// Audio extensions the server accepts.
const List<String> kAllowedAudioExtensions = [
  'mp3',
  'm4a',
  'aac',
  'wav',
  'flac',
  'ogg',
];

/// Extensions `flutter_soloud` can read — the fallback waveform builder on
/// Windows/Linux.
const List<String> kDesktopAudioExtensions = ['mp3', 'wav', 'flac', 'ogg'];

/// Formats offered in the file picker.
List<String> get allowedAudioExtensions => kAllowedAudioExtensions;

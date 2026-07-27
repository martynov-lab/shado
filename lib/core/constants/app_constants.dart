/// Разделитель кусков текста, который пользователь ставит вручную.
const String kSegmentDelimiter = '|';

/// Минимальная длительность куска — не даём меткам схлопываться.
const int kMinSegmentGapMs = 200;

/// Скорости воспроизведения урока.
const double kNormalSpeed = 1.0;
const double kSlowSpeed = 0.75;

/// Число столбиков, до которого прореживаются пики волны перед отрисовкой.
const int kWaveformResolution = 2000;

/// Расширения аудио, которые принимаем при выборе файла.
const List<String> kAllowedAudioExtensions = ['mp3', 'm4a', 'wav'];

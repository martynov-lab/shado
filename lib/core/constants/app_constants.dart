/// Разделитель кусков текста, который пользователь ставит вручную.
const String kSegmentDelimiter = '|';

/// Минимальная длительность куска — не даём меткам схлопываться.
const int kMinSegmentGapMs = 200;

/// Минимальная длительность того, что остаётся после обрезки: метки обрезки
/// ближе друг к другу не сходятся.
const int kMinTrimMs = 500;

/// Скорости воспроизведения урока.
const double kNormalSpeed = 1.0;
const double kSlowSpeed = 0.75;

/// Число столбиков, до которого прореживаются пики волны перед отрисовкой.
const int kWaveformResolution = 2000;

/// Расширения аудио, которые принимает сервер. Список один на все платформы:
/// файл декодирует он же, поэтому возможности локальных декодеров больше не
/// ограничивают выбор.
const List<String> kAllowedAudioExtensions = [
  'mp3',
  'm4a',
  'aac',
  'wav',
  'flac',
  'ogg',
];

/// Что умеет прочитать `flutter_soloud` — запасной построитель волны на
/// Windows/Linux, когда сервер недоступен. m4a и aac его декодер не читает.
const List<String> kDesktopAudioExtensions = ['mp3', 'wav', 'flac', 'ogg'];

/// Форматы, доступные при выборе файла.
List<String> get allowedAudioExtensions => kAllowedAudioExtensions;

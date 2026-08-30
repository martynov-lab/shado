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

/// Скорости, доступные в настройке «Скорость по умолчанию».
const List<double> kPlaybackSpeeds = [0.5, 0.6, 0.75, 0.9, 1.0, 1.25, 1.5];

/// Подпись скорости для UI — «1.0×».
String speedLabel(double speed) => '$speed×';

/// Сколько раз повторять отрезок в цикле: границы и значение по умолчанию.
/// [kInfiniteRepeats] (0) — крутить бесконечно, пока включён повтор; в UI это
/// нижний край шкалы и показывается знаком бесконечности, дальше идут 1…10.
const int kInfiniteRepeats = 0;
const int kMinRepeatsInCycle = kInfiniteRepeats;
const int kMaxRepeatsInCycle = 10;
const int kDefaultRepeatsInCycle = 3;

/// Подпись числа повторов для UI: «∞» для бесконечного цикла, иначе само число.
String repeatsLabel(int repeats) =>
    repeats == kInfiniteRepeats ? '∞' : '$repeats';

/// Число столбиков, до которого прореживаются пики волны перед отрисовкой.
const int kWaveformResolution = 2000;

/// Предел длины текста для озвучки через ИИ (`POST /v1/tts/synthesize`).
/// Сервер отвергает более длинный `422` ещё до обращения к провайдеру (Gemini
/// TTS) — проверяем на клиенте, чтобы не тратить попытку зря.
const int kMaxTtsChars = 2000;

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

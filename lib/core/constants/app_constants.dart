import '../platform/platform_setup.dart';

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

/// Расширения аудио, которые принимаем при выборе файла на мобильных.
const List<String> kAllowedAudioExtensions = ['mp3', 'm4a', 'wav'];

/// То же для Windows/Linux: декодер `flutter_soloud`, который там строит волну,
/// m4a не читает, зато умеет flac и ogg.
const List<String> kDesktopAudioExtensions = ['mp3', 'wav', 'flac', 'ogg'];

/// Форматы, доступные на текущей платформе.
List<String> get allowedAudioExtensions =>
    isPluginlessDesktop ? kDesktopAudioExtensions : kAllowedAudioExtensions;

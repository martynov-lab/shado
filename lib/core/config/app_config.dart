/// Настройки сборки, задаваемые через `--dart-define`.
///
/// По умолчанию приложение смотрит на локальный сервер, поднятый рядом
/// (`shado_server`, `127.0.0.1:8080`). Прод-сборка передаёт свой адрес:
/// `flutter build --dart-define=SHADO_API_BASE_URL=https://…`.
class AppConfig {
  const AppConfig._();

  /// Корень API без завершающего слэша. Версия живёт в путях (`/v1/...`),
  /// поэтому в базовый URL она не входит.
  static const String apiBaseUrl = String.fromEnvironment(
    'SHADO_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  /// Предел размера аудио на сервере. Проверяем до отправки, чтобы не гонять
  /// зря трафик и не ловить `payload_too_large` после минуты загрузки.
  static const int maxUploadBytes = 50 * 1024 * 1024;

  /// Сколько времени ждём ответа на обычный запрос. Загрузка и скачивание
  /// файла идут без этого предела — там свои таймауты.
  static const Duration requestTimeout = Duration(seconds: 20);

  static const Duration connectTimeout = Duration(seconds: 10);
}

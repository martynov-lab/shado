/// Build settings supplied through `--dart-define`.
class AppConfig {
  const AppConfig._();

  /// API root without a trailing slash; the version lives in paths (`/v1/...`).
  static const String apiBaseUrl = String.fromEnvironment(
    'SHADO_API_BASE_URL',
    defaultValue: 'https://shado-martin.duckdns.org',
  );

  /// Maximum audio size the server accepts.
  static const int maxUploadBytes = 50 * 1024 * 1024;

  /// Response timeout for a regular request.
  static const Duration requestTimeout = Duration(seconds: 60);

  static const Duration connectTimeout = Duration(seconds: 15);

  /// Audio file transfer timeout.
  static const Duration audioTimeout = Duration(minutes: 10);
}

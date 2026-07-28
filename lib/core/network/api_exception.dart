import '../error/failures.dart';

/// Коды ошибок API. Один список на весь сервер, см. §1 спецификации клиента.
///
/// [unknown] — не «всё хорошо», а «сервер прислал код, которого мы не знаем»:
/// такую ошибку разбираем по HTTP-статусу и показываем как общую.
enum ApiErrorCode {
  validationError('validation_error'),
  invalidCredentials('invalid_credentials'),
  emailTaken('email_taken'),
  unauthorized('unauthorized'),
  forbidden('forbidden'),
  notFound('not_found'),
  versionConflict('version_conflict'),
  payloadTooLarge('payload_too_large'),
  unsupportedMediaType('unsupported_media_type'),
  rateLimited('rate_limited'),
  internalError('internal_error'),
  unknown('unknown');

  const ApiErrorCode(this.wire);

  /// Значение, которое приходит в `error.code`.
  final String wire;

  static ApiErrorCode parse(String? raw) {
    for (final code in values) {
      if (code.wire == raw) return code;
    }
    return unknown;
  }
}

/// Ошибка, пришедшая от API. Дальше сетевого слоя `DioException` не уходит:
/// репозитории и контроллеры видят только её.
class ApiException extends Failure {
  const ApiException({
    required this.code,
    required String message,
    this.status,
    this.details,
    super.cause,
  }) : super(message);

  final ApiErrorCode code;

  /// HTTP-статус ответа; `null`, если ответа не было вовсе.
  final int? status;

  /// Тело `error` целиком — там же лежит `current` при [ApiErrorCode.versionConflict].
  final Map<String, dynamic>? details;

  /// Актуальное состояние ресурса при конфликте версий (§6).
  Map<String, dynamic>? get current =>
      details?['current'] as Map<String, dynamic>?;

  bool get isUnauthorized => code == ApiErrorCode.unauthorized;

  bool get isNotFound => code == ApiErrorCode.notFound;

  bool get isVersionConflict => code == ApiErrorCode.versionConflict;

  @override
  String toString() => message;
}

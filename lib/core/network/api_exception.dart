import '../error/failures.dart';

/// API error codes; [unknown] is a code the client does not know.
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
  // AI voice-over codes.
  ttsQuotaExceeded('tts_quota_exceeded'),
  ttsUnavailable('tts_unavailable'),
  internalError('internal_error'),
  unknown('unknown');

  const ApiErrorCode(this.wire);

  /// Value that arrives in `error.code`.
  final String wire;

  static ApiErrorCode parse(String? raw) {
    for (final code in values) {
      if (code.wire == raw) return code;
    }
    return unknown;
  }
}

/// Failure returned by the API.
class ApiException extends Failure {
  const ApiException({
    required this.code,
    required String message,
    this.status,
    this.details,
    super.cause,
  }) : super(message);

  final ApiErrorCode code;

  /// HTTP status of the response; `null` when there was none.
  final int? status;

  /// The whole `error` body.
  final Map<String, dynamic>? details;

  /// Current resource state on a version conflict.
  Map<String, dynamic>? get current =>
      details?['current'] as Map<String, dynamic>?;

  bool get isUnauthorized => code == ApiErrorCode.unauthorized;

  bool get isForbidden => code == ApiErrorCode.forbidden;

  bool get isNotFound => code == ApiErrorCode.notFound;

  bool get isVersionConflict => code == ApiErrorCode.versionConflict;

  @override
  String toString() => message;
}

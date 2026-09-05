import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/failures.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// API client: returns parsed JSON and reports failures as [ApiException] or
/// [NetworkFailure].
class ApiClient {
  ApiClient({
    required TokenStorage tokens,
    Dio? dio,
    String baseUrl = AppConfig.apiBaseUrl,
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: AppConfig.connectTimeout,
               receiveTimeout: AppConfig.requestTimeout,
               // Shared limit sized for the heaviest request — an audio upload.
               sendTimeout: AppConfig.audioTimeout,
               contentType: Headers.jsonContentType,
               // We parse statuses ourselves: the error body carries a code.
               responseType: ResponseType.json,
             ),
           ) {
    this.dio.options.baseUrl = baseUrl;
    this.dio.interceptors.add(
      AuthInterceptor(
        dio: this.dio,
        tokens: tokens,
        onSessionExpired: () => _onSessionExpired?.call() ?? Future.value(),
      ),
    );
  }

  /// Retry count for a request that never reached the server.
  static const int _retries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 400);
  static const Set<String> _idempotent = {'GET', 'PUT', 'DELETE', 'HEAD'};

  final Dio dio;

  Future<void> Function()? _onSessionExpired;

  /// Expired session handler — navigates to `/login`.
  set onSessionExpired(Future<void> Function() handler) =>
      _onSessionExpired = handler;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    final response = await _send<Map<String, dynamic>>(
      () => dio.get(path, queryParameters: query, options: options),
    );
    return response.data ?? const {};
  }

  /// Like [get] but keeps response headers — `ETag` arrives there.
  Future<Response<Map<String, dynamic>>> getRaw(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _send<Map<String, dynamic>>(
      () => dio.get(path, queryParameters: query, options: options),
    );
  }

  Future<Response<Map<String, dynamic>>> post(
    String path, {
    Object? data,
    Options? options,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _send<Map<String, dynamic>>(
      () => dio.post(
        path,
        data: data,
        options: options,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> put(
    String path, {
    Object? data,
    Options? options,
  }) {
    return _send<Map<String, dynamic>>(
      () => dio.put(path, data: data, options: options),
    );
  }

  Future<Response<Map<String, dynamic>>> patch(
    String path, {
    Object? data,
    Options? options,
  }) {
    return _send<Map<String, dynamic>>(
      () => dio.patch(path, data: data, options: options),
    );
  }

  Future<void> delete(String path, {Options? options}) {
    return _send<dynamic>(() => dio.delete(path, options: options));
  }

  Future<Response<dynamic>> download(
    String path,
    String savePath, {
    Options? options,
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
    bool append = false,
  }) {
    // Downloads are not retried here: they have their own `Range` logic.
    return _guard(
      () => dio.download(
        path,
        savePath,
        options: options,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        fileAccessMode: append ? FileAccessMode.append : FileAccessMode.write,
      ),
    );
  }

  /// Request retried on network failures — idempotent methods only.
  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    var attempt = 0;
    while (true) {
      try {
        return await _guard(request);
      } on NetworkFailure catch (failure) {
        final method = _methodOf(failure);
        if (attempt >= _retries || !_idempotent.contains(method)) rethrow;
        attempt++;
        await Future<void>.delayed(_retryDelay * attempt);
      }
    }
  }

  /// HTTP method of the request that failed.
  static String _methodOf(NetworkFailure failure) {
    final cause = failure.cause;
    if (cause is DioException) {
      return cause.requestOptions.method.toUpperCase();
    }
    return '';
  }

  /// Converts a `DioException` into an application failure.
  Future<R> _guard<R>(Future<R> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw mapError(error);
    }
  }

  /// Parses a response into [ApiException]; unknown codes map to
  /// [ApiErrorCode.unknown].
  static Failure mapError(DioException error) {
    final response = error.response;
    if (response == null) {
      if (error.type == DioExceptionType.cancel) {
        return NetworkFailure('Запрос отменён', cause: error);
      }
      return NetworkFailure(_networkMessage(error), cause: error);
    }

    final body = _errorBody(response.data);
    final code = ApiErrorCode.parse(body?['code'] as String?);
    final message = body?['message'] as String?;
    return ApiException(
      code: code,
      message: (message == null || message.isEmpty)
          ? _statusMessage(response.statusCode)
          : message,
      status: response.statusCode,
      details: body,
      cause: error,
    );
  }

  /// Error body from `{"error": {...}}`; `null` for a foreign format.
  static Map<String, dynamic>? _errorBody(Object? data) {
    if (data is Map && data['error'] is Map) {
      return Map<String, dynamic>.from(data['error'] as Map);
    }
    return null;
  }

  static String _networkMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'Сервер не ответил вовремя',
      _ => 'Нет связи с сервером',
    };
  }

  static String _statusMessage(int? status) => switch (status) {
    401 => 'Требуется вход',
    403 => 'Доступ запрещён',
    404 => 'Не найдено',
    409 => 'Конфликт данных',
    413 => 'Файл слишком большой',
    415 => 'Формат не поддерживается',
    422 => 'Сервер отклонил данные',
    429 => 'Слишком много попыток, подождите минуту',
    _ => 'Ошибка сервера ($status)',
  };
}

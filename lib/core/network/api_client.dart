import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/failures.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Единственная дверь в API. Наружу отдаёт разобранный JSON, а всякий сбой —
/// [ApiException] или [NetworkFailure]: `DioException` дальше не уходит.
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
               // Отправка — единственный шаг, где тело бывает на 50 МБ,
               // поэтому предел общий и щедрый: JSON-запросы всё равно
               // упираются в connect- и receiveTimeout раньше.
               sendTimeout: AppConfig.audioTimeout,
               contentType: Headers.jsonContentType,
               // Разбираем статусы сами: ошибочный ответ несёт тело с кодом,
               // который нужен целиком.
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

  /// Сколько раз повторяем запрос, не дошедший до сервера. Повторяем только
  /// идемпотентное: у `PUT` идентификатор задаёт клиент, поэтому дубля не будет.
  static const int _retries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 400);
  static const Set<String> _idempotent = {'GET', 'PUT', 'DELETE', 'HEAD'};

  final Dio dio;

  Future<void> Function()? _onSessionExpired;

  /// Кто уводит на `/login`, когда сессия кончилась. Ставится один раз при
  /// сборке зависимостей.
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

  /// Как [get], но с заголовками ответа: `ETag` урока приходит именно там.
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
    // Докачку не повторяем автоматически: у неё своя логика с `Range`.
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

  /// Запрос с повтором на сетевых сбоях.
  ///
  /// Повторяем только то, что можно повторить безопасно: ответ на `POST`
  /// мог потеряться уже после того, как сервер его выполнил.
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

  /// HTTP-метод запроса, породившего сбой: он лежит в исходном `DioException`.
  static String _methodOf(NetworkFailure failure) {
    final cause = failure.cause;
    if (cause is DioException) {
      return cause.requestOptions.method.toUpperCase();
    }
    return '';
  }

  /// Превращает `DioException` в ошибку приложения.
  Future<R> _guard<R>(Future<R> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw mapError(error);
    }
  }

  /// Разбор ответа в [ApiException] по §1 спецификации.
  ///
  /// Неизвестный код — не повод считать, что всё хорошо: он превращается в
  /// [ApiErrorCode.unknown] с сообщением по HTTP-статусу.
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

  /// Тело ошибки приходит как `{"error": {...}}`; всё остальное — не наш
  /// формат, и разбирать там нечего.
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

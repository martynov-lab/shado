import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Подставляет `Authorization` и обновляет протухший access.
///
/// Обновление идёт одно на все параллельные запросы: пять экранов, одновременно
/// получившие 401, ждут один `POST /v1/auth/refresh` и повторяются с новым
/// токеном.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokens,
    required Future<void> Function() onSessionExpired,
  }) : _dio = dio,
       _tokens = tokens,
       _onSessionExpired = onSessionExpired;

  /// Запросы, которым `Authorization` не нужен: `/v1/auth/*` и сам refresh.
  static const String skipAuthKey = 'skipAuth';

  final Dio _dio;
  final TokenStorage _tokens;

  /// Полный выход: чистка токенов, кеша уроков и аудио, возврат на `/login`.
  /// Сетевой слой сам этого не умеет — дёргает того, кто умеет.
  final Future<void> Function() _onSessionExpired;

  Future<String?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final access = _tokens.accessToken;
    if (access != null && options.extra[skipAuthKey] != true) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final skipAuth = err.requestOptions.extra[skipAuthKey] == true;
    if (err.response?.statusCode != 401 ||
        skipAuth ||
        path.startsWith('/v1/auth/')) {
      return handler.next(err);
    }

    final access = await (_refreshing ??= _refresh().whenComplete(() {
      _refreshing = null;
    }));
    if (access == null) return handler.next(err);

    final options = err.requestOptions
      ..headers['Authorization'] = 'Bearer $access';
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Меняет refresh на новую пару. `null` — обновиться не удалось.
  ///
  /// 401 здесь означает, что цепочка refresh-токенов погашена целиком (сервер
  /// так реагирует на повторно предъявленный токен — признак кражи), поэтому
  /// молча ретраить бессмысленно: это полный выход.
  Future<String?> _refresh() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null) return null;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(extra: {skipAuthKey: true}),
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _tokens.save(tokens);
      return tokens.accessToken;
    } on DioException catch (error) {
      // Сеть отвалилась — сессия цела, вернём ошибку исходному запросу и дадим
      // повторить позже. А вот отказ сервера означает конец сессии.
      if (error.response != null) {
        await _tokens.clear();
        await _onSessionExpired();
      }
      return null;
    }
  }
}

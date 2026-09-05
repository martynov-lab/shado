import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Adds `Authorization` and refreshes a stale access token with a single
/// request shared by all concurrent 401s.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokens,
    required Future<void> Function() onSessionExpired,
  }) : _dio = dio,
       _tokens = tokens,
       _onSessionExpired = onSessionExpired;

  /// `extra` key for requests that need no `Authorization`.
  static const String skipAuthKey = 'skipAuth';

  final Dio _dio;
  final TokenStorage _tokens;

  /// Full sign-out: clears tokens and caches, returns to `/login`.
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

  /// Exchanges the refresh token for a new pair; `null` when it failed.
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
      // A server rejection ends the session; a network drop does not.
      if (error.response != null) {
        await _tokens.clear();
        await _onSessionExpired();
      }
      return null;
    }
  }
}

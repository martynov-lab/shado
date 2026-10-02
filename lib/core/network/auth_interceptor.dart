import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Adds `Authorization` and refreshes the access token with a single request
/// shared by every caller: the server revokes the whole session when a used
/// refresh token comes again.
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

  /// Without an access token (a start or an offline session) one is fetched
  /// before the request.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true) return handler.next(options);
    var access = _tokens.accessToken;
    if (access == null && await _tokens.readRefreshToken() != null) {
      try {
        access = await _sharedRefresh();
      } on DioException catch (error) {
        return handler.reject(_asFailureOf(options, error));
      }
    }
    if (access != null) options.headers['Authorization'] = 'Bearer $access';
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

    final String? access;
    try {
      access = await _sharedRefresh();
    } on DioException catch (error) {
      // The refresh failed without a verdict: report that, not the 401.
      return handler.next(_asFailureOf(err.requestOptions, error));
    }
    if (access == null) return handler.next(err);

    final options = err.requestOptions
      ..headers['Authorization'] = 'Bearer $access';
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _sharedRefresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  /// Exchanges the refresh token for a new pair; `null` when there is none or
  /// the server rejected it. Other failures are thrown.
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
      // Only a 401 ends the session; a network drop or a server error does not.
      if (error.response?.statusCode != 401) rethrow;
      await _tokens.clear();
      await _onSessionExpired();
      return null;
    }
  }

  /// The refresh failure reported for [options], so retries and messages
  /// follow the original request.
  static DioException _asFailureOf(
    RequestOptions options,
    DioException error,
  ) => DioException(
    requestOptions: options,
    response: error.response,
    type: error.type,
    error: error.error,
    message: error.message,
  );
}

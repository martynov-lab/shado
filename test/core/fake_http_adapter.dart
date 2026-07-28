import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shado/core/storage/token_storage.dart';

/// Подставной транспорт: каждый запрос обслуживает переданная функция.
///
/// Свой адаптер, а не готовый мок, потому что проверять надо порядок и число
/// вызовов — например, что на три параллельных 401 приходится один refresh.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// Все запросы в том порядке, в каком их отдавали.
  final List<RequestOptions> requests = [];

  int countOf(String path) =>
      requests.where((request) => request.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Ответ с JSON-телом.
ResponseBody jsonResponse(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Ошибка в формате API: `{"error": {"code": ..., "message": ...}}`.
ResponseBody errorResponse(
  int status,
  String code, {
  String message = 'что-то пошло не так',
  Map<String, dynamic>? extra,
}) {
  return jsonResponse(status, {
    'error': {'code': code, 'message': message, ...?extra},
  });
}

/// Хранилище токенов в памяти: тесту не нужен keychain.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({String? access, String? refresh})
    : _access = access,
      _refresh = refresh;

  String? _access;
  String? _refresh;

  /// Сколько раз сохраняли пару — по нему видно ротацию refresh-токена.
  int saves = 0;
  bool cleared = false;

  @override
  String? get accessToken => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> save(AuthTokens tokens) async {
    saves++;
    _access = tokens.accessToken;
    _refresh = tokens.refreshToken;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    _access = null;
    _refresh = null;
  }
}

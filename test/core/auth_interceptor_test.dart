import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/core/network/api_exception.dart';

import 'fake_http_adapter.dart';

void main() {
  /// Сервер, который отдаёт 401 на защищённые пути, пока не выдан новый access.
  ///
  /// [refreshStatus] — чем отвечает сам `/v1/auth/refresh`.
  ({ApiClient client, FakeHttpAdapter adapter, FakeTokenStorage tokens})
  buildExpiredSession({
    int refreshStatus = 200,
    Duration refreshDelay = Duration.zero,
    Future<void> Function()? onSessionExpired,
  }) {
    final tokens = FakeTokenStorage(access: 'stale', refresh: 'refresh-1');
    late FakeHttpAdapter adapter;

    adapter = FakeHttpAdapter((options) async {
      if (options.path == '/v1/auth/refresh') {
        if (refreshDelay > Duration.zero) {
          await Future<void>.delayed(refreshDelay);
        }
        if (refreshStatus != 200) {
          return errorResponse(refreshStatus, 'unauthorized');
        }
        return jsonResponse(200, {
          'access_token': 'fresh',
          'refresh_token': 'refresh-2',
          'expires_in': 900,
        });
      }
      // Пока токен не обновлён, любой защищённый путь отвечает 401.
      final authorization = options.headers['Authorization'];
      if (authorization != 'Bearer fresh') {
        return errorResponse(401, 'unauthorized', message: 'токен истёк');
      }
      return jsonResponse(200, {'path': options.path});
    });

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(
      tokens: tokens,
      dio: dio,
      baseUrl: 'http://localhost',
    );
    if (onSessionExpired != null) client.onSessionExpired = onSessionExpired;
    return (client: client, adapter: adapter, tokens: tokens);
  }

  test('протухший access обновляется молча, запрос повторяется', () async {
    final env = buildExpiredSession();

    final result = await env.client.get('/v1/me');

    expect(result['path'], '/v1/me');
    expect(env.adapter.countOf('/v1/auth/refresh'), 1);
    // Исходный запрос: первый раз с протухшим токеном, второй — с новым.
    expect(env.adapter.countOf('/v1/me'), 2);
  });

  test('новый refresh-токен сохраняется — старый больше не работает', () async {
    final env = buildExpiredSession();

    await env.client.get('/v1/me');

    expect(await env.tokens.readRefreshToken(), 'refresh-2');
    expect(env.tokens.accessToken, 'fresh');
    expect(env.tokens.saves, 1);
  });

  test('несколько параллельных 401 обходятся одним refresh', () async {
    // Обновление держим искусственно медленным: без общей очереди каждый из
    // трёх запросов успел бы запустить своё.
    final env = buildExpiredSession(
      refreshDelay: const Duration(milliseconds: 50),
    );

    final responses = await Future.wait([
      env.client.get('/v1/lessons'),
      env.client.get('/v1/me'),
      env.client.get('/v1/lessons/1'),
    ]);

    expect(responses, hasLength(3));
    expect(env.adapter.countOf('/v1/auth/refresh'), 1);
    expect(env.tokens.saves, 1);
  });

  test('401 на самом refresh — полный выход', () async {
    var signedOut = false;
    final env = buildExpiredSession(
      refreshStatus: 401,
      onSessionExpired: () async => signedOut = true,
    );

    await expectLater(
      env.client.get('/v1/me'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.isUnauthorized,
          'unauthorized',
          isTrue,
        ),
      ),
    );
    // Сервер гасит всю цепочку refresh-токенов, если пришёл уже
    // использованный, — ретраить бессмысленно, сессии больше нет.
    expect(env.tokens.cleared, isTrue);
    expect(signedOut, isTrue);
    expect(env.adapter.countOf('/v1/auth/refresh'), 1);
  });

  test('без refresh-токена обновляться нечем', () async {
    final tokens = FakeTokenStorage(access: 'stale');
    final adapter = FakeHttpAdapter(
      (options) async => errorResponse(401, 'unauthorized'),
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(
      tokens: tokens,
      dio: dio,
      baseUrl: 'http://localhost',
    );

    await expectLater(client.get('/v1/me'), throwsA(isA<ApiException>()));
    expect(adapter.countOf('/v1/auth/refresh'), 0);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/core/network/api_exception.dart';

import 'fake_http_adapter.dart';

void main() {
  /// A server returning 401 on protected paths until a new access token.
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
      // Until the token is refreshed every protected path answers 401.
      final authorization = options.headers['Authorization'];
      if (authorization != 'Bearer fresh') {
        return errorResponse(401, 'unauthorized', message: 'token expired');
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

  test('a stale access token is refreshed silently and the request retried', () async {
    final env = buildExpiredSession();

    final result = await env.client.get('/v1/me');

    expect(result['path'], '/v1/me');
    expect(env.adapter.countOf('/v1/auth/refresh'), 1);
    // The original request: first with a stale token, then with a fresh one.
    expect(env.adapter.countOf('/v1/me'), 2);
  });

  test('the new refresh token is saved and the old one stops working', () async {
    final env = buildExpiredSession();

    await env.client.get('/v1/me');

    expect(await env.tokens.readRefreshToken(), 'refresh-2');
    expect(env.tokens.accessToken, 'fresh');
    expect(env.tokens.saves, 1);
  });

  test('several parallel 401s get by with a single refresh', () async {
    // The refresh is kept slow so the requests overlap.
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

  test('a 401 on the refresh itself signs the user out', () async {
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
    // A server refusal on refresh closes the whole session.
    expect(env.tokens.cleared, isTrue);
    expect(signedOut, isTrue);
    expect(env.adapter.countOf('/v1/auth/refresh'), 1);
  });

  test('without a refresh token there is nothing to refresh', () async {
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

  test('a server error on the refresh keeps the session', () async {
    var signedOut = false;
    final env = buildExpiredSession(
      refreshStatus: 502,
      onSessionExpired: () async => signedOut = true,
    );

    await expectLater(env.client.get('/v1/me'), throwsA(isA<ApiException>()));
    expect(env.tokens.cleared, isFalse);
    expect(signedOut, isFalse);
  });

  group('offline session', () {
    /// No access token yet, as after an offline start; [refreshOffline]
    /// makes the refresh fail without reaching the server.
    ({ApiClient client, FakeHttpAdapter adapter, FakeTokenStorage tokens})
    buildWithoutAccess({bool refreshOffline = false}) {
      final tokens = FakeTokenStorage(refresh: 'refresh-1');
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/v1/auth/refresh') {
          if (refreshOffline) {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'offline',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return jsonResponse(200, {
            'access_token': 'fresh',
            'refresh_token': 'refresh-2',
            'expires_in': 900,
          });
        }
        if (options.headers['Authorization'] != 'Bearer fresh') {
          return errorResponse(401, 'unauthorized');
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
      return (client: client, adapter: adapter, tokens: tokens);
    }

    test('parallel requests after a reconnect share one refresh', () async {
      final env = buildWithoutAccess();

      await Future.wait([
        env.client.get('/v1/me'),
        env.client.get('/v1/lessons'),
        env.client.get('/v1/progress'),
      ]);

      expect(env.adapter.countOf('/v1/auth/refresh'), equals(1));
      // The token is fetched before the request, so nothing hits a 401.
      expect(env.adapter.countOf('/v1/me'), equals(1));
      expect(await env.tokens.readRefreshToken(), equals('refresh-2'));
    });

    test(
      'a refresh that never reached the server is a network failure',
      () async {
        final env = buildWithoutAccess(refreshOffline: true);

        await expectLater(
          env.client.get('/v1/me'),
          throwsA(isA<NetworkFailure>()),
        );
        expect(env.tokens.cleared, isFalse);
        expect(await env.tokens.readRefreshToken(), equals('refresh-1'));
      },
    );
  });
}

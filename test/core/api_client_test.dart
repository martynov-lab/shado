import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/core/network/api_exception.dart';

import 'fake_http_adapter.dart';

void main() {
  /// A client on top of the stub transport.
  ({ApiClient client, FakeHttpAdapter adapter, FakeTokenStorage tokens}) build(
    Future<ResponseBody> Function(RequestOptions options) handler, {
    String? access,
    String? refresh,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    final adapter = FakeHttpAdapter(handler);
    dio.httpClientAdapter = adapter;
    final tokens = FakeTokenStorage(access: access, refresh: refresh);
    final client = ApiClient(
      tokens: tokens,
      dio: dio,
      baseUrl: 'http://localhost',
    );
    return (client: client, adapter: adapter, tokens: tokens);
  }

  group('error parsing', () {
    /// Every spec error code must reach the caller unchanged.
    const cases = <(int, String, ApiErrorCode)>[
      (422, 'validation_error', ApiErrorCode.validationError),
      (401, 'invalid_credentials', ApiErrorCode.invalidCredentials),
      (409, 'email_taken', ApiErrorCode.emailTaken),
      (403, 'forbidden', ApiErrorCode.forbidden),
      (404, 'not_found', ApiErrorCode.notFound),
      (409, 'version_conflict', ApiErrorCode.versionConflict),
      (413, 'payload_too_large', ApiErrorCode.payloadTooLarge),
      (415, 'unsupported_media_type', ApiErrorCode.unsupportedMediaType),
      (429, 'rate_limited', ApiErrorCode.rateLimited),
      (429, 'tts_quota_exceeded', ApiErrorCode.ttsQuotaExceeded),
      (503, 'tts_unavailable', ApiErrorCode.ttsUnavailable),
      (500, 'internal_error', ApiErrorCode.internalError),
    ];

    for (final (status, wire, expected) in cases) {
      test('$wire → $expected', () async {
        final env = build(
          (options) async =>
              errorResponse(status, wire, message: 'server message'),
        );

        await expectLater(
          env.client.get('/v1/lessons'),
          throwsA(
            isA<ApiException>()
                .having((error) => error.code, 'code', expected)
                .having((error) => error.status, 'status', status)
                .having((error) => error.message, 'message', 'server message'),
          ),
        );
      });
    }

    test('an unknown code does not pass for success', () async {
      final env = build(
        (options) async => errorResponse(418, 'teapot_error', message: ''),
      );

      await expectLater(
        env.client.get('/v1/lessons'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', ApiErrorCode.unknown)
              .having((error) => error.status, 'status', 418),
        ),
      );
    });

    test('a version conflict carries the current lesson in error.current', () async {
      final env = build(
        (options) async => errorResponse(
          409,
          'version_conflict',
          message: 'version conflict',
          extra: {
            'current': {'id': '9f1c', 'version': 4},
          },
        ),
      );

      try {
        await env.client.put('/v1/lessons/9f1c');
        fail('expected a conflict');
      } on ApiException catch (error) {
        expect(error.isVersionConflict, isTrue);
        expect(error.current?['version'], 4);
      }
    });

    test('a dropped connection is not an API error', () async {
      final env = build(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no network',
        ),
      );

      await expectLater(
        env.client.get('/v1/me'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('a network failure on GET is retried, but not forever', () async {
      final env = build(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no network',
        ),
      );

      await expectLater(
        env.client.get('/v1/me'),
        throwsA(isA<NetworkFailure>()),
      );
      // The first attempt plus two retries.
      expect(env.adapter.countOf('/v1/me'), 3);
    });

    test('a POST is not retried after a failure: the response may be lost', () async {
      final env = build(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no network',
        ),
      );

      await expectLater(
        env.client.post('/v1/audio'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(env.adapter.countOf('/v1/audio'), 1);
    });
  });

  group('Authorization header', () {
    test('is set when an access token is present', () async {
      final env = build(
        (options) async => jsonResponse(200, {'ok': true}),
        access: 'access-1',
      );

      await env.client.get('/v1/me');

      expect(
        env.adapter.requests.single.headers['Authorization'],
        'Bearer access-1',
      );
    });

    test('is not set on /v1/auth/*', () async {
      final env = build(
        (options) async => jsonResponse(200, {'ok': true}),
        access: 'access-1',
      );

      await env.client.post(
        '/v1/auth/login',
        options: Options(extra: {'skipAuth': true}),
      );

      expect(
        env.adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });
}

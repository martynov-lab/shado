import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/lessons/data/datasources/tts_remote_datasource.dart';

import '../core/fake_http_adapter.dart';

void main() {
  ({ApiTtsRemoteDataSource remote, FakeHttpAdapter adapter}) build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    final adapter = FakeHttpAdapter(handler);
    dio.httpClientAdapter = adapter;
    final client = ApiClient(
      tokens: FakeTokenStorage(access: 'access'),
      dio: dio,
      baseUrl: 'http://localhost',
    );
    return (remote: ApiTtsRemoteDataSource(client), adapter: adapter);
  }

  test('synthesize sends a POST with the text and parses the response as audio', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'id': 'b21e',
        // Gemini TTS returns wav and the server does not re-encode it.
        'content_type': 'audio/wav',
        'size_bytes': 204844,
        'sha256': '3f2a',
        'duration_ms': 4200,
        'cached': false,
      }),
    );

    final audio = await env.remote.synthesize(text: 'Nice to meet you.');

    final request = env.adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/tts/synthesize');
    expect((request.data as Map)['text'], 'Nice to meet you.');
    expect(audio.id, 'b21e');
    expect(audio.durationMs, 4200);
    // The client does not read the cached field; it does not affect parsing.
    expect(audio.contentType, 'audio/wav');
    // The wav lands in the cache with a .wav extension.
    expect(audio.fileExtension, 'wav');
  });

  test('quota parses the remaining voice-overs; limit 0 means no cap', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'provider': 'gemini',
        'day': {'used': 3, 'limit': 14, 'remaining': 11},
        'minute': {'used': 0, 'limit': 2, 'remaining': 2},
        'month_chars': {'used': 812, 'limit': 0},
      }),
    );

    final quota = await env.remote.quota();

    final request = env.adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, '/v1/tts/quota');
    expect(quota.provider, 'gemini');
    expect(quota.day.remaining, 11);
    expect(quota.day.isUnlimited, isFalse);
    expect(quota.minute.limit, 2);
  });

  test('quota: limit 0 in a window means no cap and no remaining', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'provider': 'gemini',
        'day': {'used': 5, 'limit': 0},
        'minute': {'used': 0, 'limit': 2, 'remaining': 2},
      }),
    );

    final quota = await env.remote.quota();

    expect(quota.day.isUnlimited, isTrue);
    expect(quota.day.remaining, isNull);
  });
}

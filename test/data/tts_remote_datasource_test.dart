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

  test('synthesize шлёт POST с текстом и разбирает ответ как аудио', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'id': 'b21e',
        // Gemini TTS отдаёт wav — сервер его не перекодирует.
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
    // Поле cached клиент не читает — на разбор оно не влияет.
    expect(audio.contentType, 'audio/wav');
    // wav кладётся в кеш под расширением .wav.
    expect(audio.fileExtension, 'wav');
  });

  test('quota разбирает остаток озвучек, limit 0 — без ограничения', () async {
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

  test('quota: limit 0 в окне — без ограничения, remaining отсутствует', () async {
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

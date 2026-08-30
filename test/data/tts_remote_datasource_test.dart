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
        'content_type': 'audio/mpeg',
        'size_bytes': 29384,
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
    expect(audio.contentType, 'audio/mpeg');
  });
}

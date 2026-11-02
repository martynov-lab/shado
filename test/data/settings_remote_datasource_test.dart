import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/settings/data/datasources/settings_remote_datasource.dart';

import '../core/fake_http_adapter.dart';

void main() {
  ({ApiSettingsRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiSettingsRemoteDataSource(client), adapter: adapter);
  }

  const settingsJson = {
    'lesson_completion_reps': 10,
    'tts_provider': 'gemini',
    'tts_providers': [
      {'name': 'gemini', 'ready': true},
      {'name': 'google', 'ready': false},
    ],
  };

  test('getTtsProvider reads the active provider and the options', () async {
    final env = build((_) async => jsonResponse(200, settingsJson));

    final settings = await env.remote.getTtsProvider();

    expect(env.adapter.requests.single.path, '/v1/settings');
    expect(settings.active, 'gemini');
    expect(settings.providers.map((p) => (p.name, p.ready)), [
      ('gemini', true),
      ('google', false),
    ]);
  });

  test('setTtsProvider sends a PATCH with the provider name', () async {
    final env = build(
      (_) async => jsonResponse(200, {...settingsJson, 'tts_provider': 'google'}),
    );

    final settings = await env.remote.setTtsProvider('google');

    final request = env.adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, '/v1/settings');
    expect((request.data as Map)['tts_provider'], 'google');
    expect(settings.active, 'google');
  });
}

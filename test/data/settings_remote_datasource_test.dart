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

  test('getCompletionReps читает порог', () async {
    final env = build(
      (_) async => jsonResponse(200, {'lesson_completion_reps': 15}),
    );

    final reps = await env.remote.getCompletionReps();

    expect(env.adapter.requests.single.path, '/v1/settings');
    expect(reps, 15);
  });

  test('setCompletionReps шлёт PATCH с телом', () async {
    final env = build(
      (_) async => jsonResponse(200, {'lesson_completion_reps': 20}),
    );

    final reps = await env.remote.setCompletionReps(20);

    final request = env.adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, '/v1/settings');
    expect(
      (request.data as Map)['lesson_completion_reps'],
      20,
    );
    expect(reps, 20);
  });
}

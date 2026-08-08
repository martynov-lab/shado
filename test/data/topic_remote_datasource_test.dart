import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/lessons/data/datasources/topic_remote_datasource.dart';

import '../core/fake_http_adapter.dart';

void main() {
  ({ApiTopicRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiTopicRemoteDataSource(client), adapter: adapter);
  }

  test('list читает справочник тем', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'topics': [
          {'id': 't1', 'name': 'Travel', 'is_default': false},
          {'id': 't0', 'name': 'Other', 'is_default': true},
        ],
      }),
    );

    final topics = await env.remote.list();

    expect(env.adapter.requests.single.path, '/v1/topics');
    expect(topics.map((topic) => topic.name), ['Travel', 'Other']);
    expect(topics.last.isDefault, isTrue);
  });

  test('create шлёт POST с именем и возвращает тему', () async {
    final env = build(
      (_) async =>
          jsonResponse(201, {'id': 't2', 'name': 'Sport', 'is_default': false}),
    );

    final topic = await env.remote.create('Sport');

    final request = env.adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/topics');
    expect((request.data as Map)['name'], 'Sport');
    expect(topic.id, 't2');
    expect(topic.name, 'Sport');
  });

  test('rename шлёт PATCH на конкретную тему', () async {
    final env = build(
      (_) async =>
          jsonResponse(200, {'id': 't2', 'name': 'Sports', 'is_default': false}),
    );

    final topic = await env.remote.rename(id: 't2', name: 'Sports');

    final request = env.adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, '/v1/topics/t2');
    expect((request.data as Map)['name'], 'Sports');
    expect(topic.name, 'Sports');
  });

  test('delete шлёт DELETE на конкретную тему', () async {
    final env = build((_) async => jsonResponse(204, const {}));

    await env.remote.delete('t2');

    final request = env.adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/v1/topics/t2');
  });
}

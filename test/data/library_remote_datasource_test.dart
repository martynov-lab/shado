import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/lessons/data/datasources/library_remote_datasource.dart';

import '../core/fake_http_adapter.dart';
import 'folder_repository_test.dart' show folderJson;
import 'lesson_repository_test.dart' show lessonJson;

void main() {
  ({ApiLibraryRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiLibraryRemoteDataSource(client), adapter: adapter);
  }

  test('лента разбирается по type: папки отдельно, уроки отдельно', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'items': [
          {...folderJson(id: 'f1', lessonCount: 2), 'type': 'folder'},
          {...lessonJson(id: 'l1'), 'type': 'lesson'},
        ],
        'next_cursor': null,
      }),
    );

    final page = await env.remote.list();

    expect(env.adapter.requests.single.path, '/v1/library');
    expect(page.folders.map((dto) => dto.id), ['f1']);
    expect(page.folders.single.lessonCount, 2);
    expect(page.lessons.map((dto) => dto.id), ['l1']);
    expect(page.nextCursor, isNull);
  });

  test('незнакомый type пропускается, а не роняет экран', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'items': [
          {'type': 'playlist', 'id': 'p1'},
          {...lessonJson(id: 'l1'), 'type': 'lesson'},
        ],
      }),
    );

    final page = await env.remote.list();

    expect(page.folders, isEmpty);
    expect(page.lessons.map((dto) => dto.id), ['l1']);
  });

  test('limit и cursor уходят в запрос, since не поддержан', () async {
    final env = build((_) async => jsonResponse(200, {'items': []}));

    await env.remote.list(limit: 100, cursor: 'c1');

    final request = env.adapter.requests.single;
    expect(request.queryParameters['limit'], 100);
    expect(request.queryParameters['cursor'], 'c1');
    // `since` on the feed returns 422; the request carries no such param.
    expect(request.queryParameters.containsKey('since'), isFalse);
  });
}

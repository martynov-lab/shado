import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/lessons/data/datasources/folder_remote_datasource.dart';

import '../core/fake_http_adapter.dart';
import 'folder_repository_test.dart' show folderJson;

void main() {
  ({ApiFolderRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiFolderRemoteDataSource(client), adapter: adapter);
  }

  test('list читает страницу папок с курсором', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'items': [folderJson(id: 'f1'), folderJson(id: 'f2')],
        'next_cursor': 'c1',
      }),
    );

    final page = await env.remote.list();

    expect(env.adapter.requests.single.path, '/v1/folders');
    expect(page.items.map((dto) => dto.id), ['f1', 'f2']);
    expect(page.nextCursor, 'c1');
  });

  test('создание — PUT по клиентскому id без If-Match', () async {
    final env = build((_) async => jsonResponse(201, folderJson(id: 'f9')));

    await env.remote.putFolder(
      id: 'f9',
      title: 'Новая',
      createdAt: DateTime.utc(2026, 8, 30, 10),
    );

    final request = env.adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/v1/folders/f9');
    expect((request.data as Map)['title'], 'Новая');
    expect(request.headers.containsKey('If-Match'), isFalse);
  });

  test('правка шлёт If-Match с версией', () async {
    final env = build((_) async => jsonResponse(200, folderJson(id: 'f9')));

    await env.remote.putFolder(
      id: 'f9',
      title: 'Другое',
      createdAt: DateTime.utc(2026, 8, 30, 10),
      version: 3,
    );

    expect(env.adapter.requests.single.headers['If-Match'], '"3"');
  });

  test('добавление уроков — POST со списком id', () async {
    final env = build(
      (_) async => jsonResponse(200, folderJson(id: 'f1', lessonCount: 2)),
    );

    await env.remote.addLessons('f1', ['l1', 'l2']);

    final request = env.adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/folders/f1/lessons');
    expect((request.data as Map)['lesson_ids'], ['l1', 'l2']);
  });

  test('удаление урока из папки — DELETE по вложенному пути', () async {
    final env = build((_) async => jsonResponse(204, const {}));

    await env.remote.removeLesson('f1', 'l1');

    final request = env.adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/v1/folders/f1/lessons/l1');
  });
}

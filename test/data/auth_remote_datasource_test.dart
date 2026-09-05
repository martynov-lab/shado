import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/auth/data/datasources/auth_remote_datasource.dart';

import '../core/fake_http_adapter.dart';

void main() {
  ({ApiAuthRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiAuthRemoteDataSource(client), adapter: adapter);
  }

  Map<String, dynamic> sessionBody() => {
    'user': {
      'id': 'u1',
      'email': 'a@b.c',
      'role': 'user',
      'created_at': '2026-01-01T00:00:00Z',
    },
    'access_token': 'access',
    'refresh_token': 'refresh',
  };

  Map<String, dynamic> bodyOf(RequestOptions options) =>
      (options.data as Map).cast<String, dynamic>();

  group('register', () {
    test('непустое имя уходит в теле', () async {
      final env = build((_) async => jsonResponse(200, sessionBody()));

      await env.remote.register(
        email: 'a@b.c',
        password: 'password1',
        name: 'Андрей',
      );

      expect(bodyOf(env.adapter.requests.single)['name'], 'Андрей');
    });

    test('пустое имя не отправляем', () async {
      final env = build((_) async => jsonResponse(200, sessionBody()));

      await env.remote.register(
        email: 'a@b.c',
        password: 'password1',
        name: '   ',
      );

      expect(bodyOf(env.adapter.requests.single).containsKey('name'), isFalse);
    });
  });

  group('updateProfile', () {
    test('шлёт PATCH /v1/me только с переданными полями', () async {
      final env = build(
        (_) async => jsonResponse(200, {
          'id': 'u1',
          'email': 'a@b.c',
          'role': 'user',
          'created_at': '2026-01-01T00:00:00Z',
          'studied_language': 'en',
        }),
      );

      final user = await env.remote.updateProfile(studiedLanguage: 'en');

      final request = env.adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/v1/me');
      final body = bodyOf(request);
      expect(body['studied_language'], 'en');
      // Fields that were not passed are not sent.
      expect(body.containsKey('name'), isFalse);
      expect(body.containsKey('daily_goal_minutes'), isFalse);
      expect(user.studiedLanguage, 'en');
    });
  });
}

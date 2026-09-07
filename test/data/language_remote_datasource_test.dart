import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/languages/data/datasources/language_remote_datasource.dart';

import '../core/fake_http_adapter.dart';

void main() {
  ({ApiLanguageRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiLanguageRemoteDataSource(client), adapter: adapter);
  }

  test('the directory parses languages with and without accents', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'languages': [
          {
            'code': 'en',
            'name': 'English',
            'native_name': 'English',
            'is_default': true,
            'accents': [
              {'code': 'US', 'name': 'American', 'is_default': true},
              {'code': 'UK', 'name': 'British'},
              {'code': 'AU', 'name': 'Australian'},
            ],
          },
          {'code': 'fr', 'name': 'French', 'native_name': 'Français'},
        ],
      }),
    );

    final languages = await env.remote.list();

    expect(env.adapter.requests.single.path, '/v1/languages');
    expect(languages, hasLength(2));
    expect(languages.first.code, 'en');
    expect(languages.first.isDefault, isTrue);
    expect(languages.first.accents.map((accent) => accent.code), [
      'US',
      'UK',
      'AU',
    ]);
    // A language without accents arrives without the field at all.
    expect(languages.last.hasAccents, isFalse);
    expect(languages.last.nativeName, 'Français');
  });

  test('the directory is also read from an items wrapper', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'items': [
          {'code': 'tr', 'name': 'Turkish'},
        ],
      }),
    );

    final languages = await env.remote.list();

    expect(languages.single.code, 'tr');
    expect(languages.single.label, 'Turkish');
  });
}

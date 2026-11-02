import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/features/translation/data/datasources/translation_remote_datasource.dart';

import '../core/fake_http_adapter.dart';

void main() {
  ({ApiTranslationRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiTranslationRemoteDataSource(client), adapter: adapter);
  }

  test('languages reads the top-level array', () async {
    final env = build(
      (_) async => ResponseBody.fromString(
        jsonEncode([
          {'code': 'ru', 'name': 'Русский', 'native_name': 'Русский'},
          {'code': 'de', 'name': 'Немецкий', 'native_name': 'Deutsch'},
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );

    final languages = await env.remote.languages();

    expect(env.adapter.requests.single.path, '/v1/translation/languages');
    expect(languages.map((l) => l.code), ['ru', 'de']);
    expect(languages.last.nativeName, 'Deutsch');
  });

  test('translate posts the batch and keeps the order', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'translations': ['Привет', 'Пока'],
        'target_lang': 'ru',
      }),
    );

    final result = await env.remote.translate([
      'Hello',
      'Bye',
    ], sourceLang: 'en');

    final request = env.adapter.requests.single;
    expect(request.path, '/v1/translate/phrases');
    expect(request.data, {
      'texts': ['Hello', 'Bye'],
      'source_lang': 'en',
    });
    expect(result, ['Привет', 'Пока']);
  });

  test('an empty source language is left to the server', () async {
    final env = build(
      (_) async => jsonResponse(200, {
        'translations': ['x'],
      }),
    );

    await env.remote.translate(['x'], sourceLang: '');

    expect((env.adapter.requests.single.data as Map).containsKey('source_lang'), isFalse);
  });

  test('a spent quota surfaces as its own code', () async {
    final env = build(
      (_) async => errorResponse(429, 'translation_quota_exceeded'),
    );

    await expectLater(
      env.remote.translate(['x'], sourceLang: 'en'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.translationQuotaExceeded,
        ),
      ),
    );
  });
}

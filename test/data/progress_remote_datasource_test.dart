import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';

import '../core/fake_http_adapter.dart';

void main() {
  ({ApiProgressRemoteDataSource remote, FakeHttpAdapter adapter}) build(
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
    return (remote: ApiProgressRemoteDataSource(client), adapter: adapter);
  }

  Map<String, dynamic> summaryBody() => {
    'today': {'day': '2026-08-06', 'listened_ms': 0, 'segment_repeats': 0},
    'totals': {
      'listened_ms': 0,
      'segment_repeats': 0,
      'lessons_completed': 0,
    },
    'week_minutes': 0,
    'week': <dynamic>[],
    'recent_lesson_ids': <dynamic>[],
    'completion_reps': 10,
  };

  Map<String, dynamic> bodyOf(RequestOptions options) =>
      (options.data as Map).cast<String, dynamic>();

  group('reportEvents', () {
    test('шлёт только заданные поля', () async {
      final env = build((_) async => jsonResponse(200, summaryBody()));

      await env.remote.reportEvents(listenedMs: 5000, lessonId: 'l1');

      final request = env.adapter.requests.single;
      expect(request.path, '/v1/progress/events');
      final body = bodyOf(request);
      expect(body['listened_ms'], 5000);
      expect(body['lesson_id'], 'l1');
      expect(body.containsKey('segment_repeats'), isFalse);
      expect(body.containsKey('completed'), isFalse);
    });

    test('completed уходит отдельным полем', () async {
      final env = build((_) async => jsonResponse(200, summaryBody()));

      await env.remote.reportEvents(completed: true, lessonId: 'l1');

      final body = bodyOf(env.adapter.requests.single);
      expect(body['completed'], true);
      expect(body['lesson_id'], 'l1');
      expect(body.containsKey('listened_ms'), isFalse);
    });
  });

  group('getHistory', () {
    test('передаёт days и парсит дни', () async {
      final env = build(
        (_) async => jsonResponse(200, {
          'days': [
            {'day': '2026-08-06', 'listened_ms': 120000, 'segment_repeats': 4},
          ],
        }),
      );

      final days = await env.remote.getHistory(days: 30);

      final request = env.adapter.requests.single;
      expect(request.path, '/v1/progress/history');
      expect(request.queryParameters['days'], 30);
      expect(days, hasLength(1));
      expect(days.single.listenedMinutes, 2);
    });
  });
}

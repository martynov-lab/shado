import '../../../../core/network/api_client.dart';
import '../../domain/entities/progress_summary.dart';

/// Server-side progress; the client batches activity and sends it as events.
abstract interface class ProgressRemoteDataSource {
  /// Sends pending activity and returns a fresh summary; every field is
  /// optional and only the given ones are sent.
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  });

  Future<ProgressSummary> getSummary();

  /// Daily history over a `days` window (1..365) for long charts.
  Future<List<ProgressDay>> getHistory({int days});
}

class ApiProgressRemoteDataSource implements ProgressRemoteDataSource {
  const ApiProgressRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async {
    final response = await _client.post(
      '/v1/progress/events',
      data: {
        'listened_ms': ?listenedMs,
        'segment_repeats': ?segmentRepeats,
        'lesson_id': ?lessonId,
        'completed': ?completed,
      },
    );
    return ProgressSummary.fromJson(response.data!);
  }

  @override
  Future<ProgressSummary> getSummary() async {
    final json = await _client.get('/v1/progress');
    return ProgressSummary.fromJson(json);
  }

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async {
    final json = await _client.get(
      '/v1/progress/history',
      query: {'days': days},
    );
    return [
      for (final day in (json['days'] as List<dynamic>? ?? const []))
        ProgressDay.fromJson(Map<String, dynamic>.from(day as Map)),
    ];
  }
}

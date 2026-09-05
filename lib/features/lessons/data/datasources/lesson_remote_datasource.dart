import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_category.dart';
import '../models/lesson_dto.dart';
import '../models/segment_model.dart';

/// A page of the lesson list.
class LessonPage {
  const LessonPage({required this.items, this.nextCursor});

  final List<LessonDto> items;

  /// `null` when there are no more pages.
  final String? nextCursor;
}

/// Server-side lessons.
abstract interface class LessonRemoteDataSource {
  /// Lesson list; with [since] a delta arrives, deleted ones included.
  Future<LessonPage> list({String? since, int? limit, String? cursor});

  Future<LessonDto> getLesson(String id);

  /// Creates or replaces a whole lesson; a `null` [version] means creation.
  Future<LessonDto> putLesson({
    required String id,
    required String title,
    required String audioId,
    required DateTime createdAt,
    required List<SegmentModel> segments,
    int? version,
    LessonAccent? accent,
    LessonLevel? level,
    String? topicId,
    bool? isPublic,
  });

  Future<void> deleteLesson(String id);
}

class ApiLessonRemoteDataSource implements LessonRemoteDataSource {
  const ApiLessonRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<LessonPage> list({String? since, int? limit, String? cursor}) async {
    final json = await _client.get(
      '/v1/lessons',
      query: {'since': ?since, 'limit': ?limit, 'cursor': ?cursor},
    );
    return LessonPage(
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          LessonDto.fromJson(item as Map<String, dynamic>),
      ],
      nextCursor: json['next_cursor'] as String?,
    );
  }

  @override
  Future<LessonDto> getLesson(String id) async {
    final json = await _client.get('/v1/lessons/$id');
    return LessonDto.fromJson(json);
  }

  @override
  Future<LessonDto> putLesson({
    required String id,
    required String title,
    required String audioId,
    required DateTime createdAt,
    required List<SegmentModel> segments,
    int? version,
    LessonAccent? accent,
    LessonLevel? level,
    String? topicId,
    bool? isPublic,
  }) async {
    final response = await _client.put(
      '/v1/lessons/$id',
      data: {
        'title': title,
        'audio_id': audioId,
        'created_at': createdAt.toUtc().toIso8601String(),
        'accent': ?accent?.wire,
        'level': ?level?.wire,
        // Without a topic the key is omitted and the server picks the default.
        'topic_id': ?topicId,
        // Visibility is sent only when the author controls it.
        'is_public': ?isPublic,
        'segments': [for (final segment in segments) segment.toJson()],
      },
      // Edits carry `If-Match`, creation does not.
      options: version == null
          ? null
          : Options(headers: {'If-Match': '"$version"'}),
    );
    return LessonDto.fromJson(response.data!);
  }

  @override
  Future<void> deleteLesson(String id) => _client.delete('/v1/lessons/$id');
}

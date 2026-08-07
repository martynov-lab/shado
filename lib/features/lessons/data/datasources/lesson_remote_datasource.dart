import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_category.dart';
import '../models/lesson_dto.dart';
import '../models/segment_model.dart';

/// Страница списка уроков.
class LessonPage {
  const LessonPage({required this.items, this.nextCursor});

  final List<LessonDto> items;

  /// `null` — страниц больше нет.
  final String? nextCursor;
}

/// Уроки на сервере — источник истины.
abstract interface class LessonRemoteDataSource {
  /// Список уроков.
  ///
  /// Без [since] приходят только живые уроки — так делается первый запуск.
  /// С [since] приходит дельта, включая мягко удалённые: по ним из кеша
  /// убираются записи, удалённые на другом устройстве.
  Future<LessonPage> list({String? since, int? limit, String? cursor});

  Future<LessonDto> getLesson(String id);

  /// Создаёт или обновляет урок.
  ///
  /// `PUT`, а не `POST`, потому что UUID генерит клиент: повтор после потери
  /// сети не создаёт дубль. [version] — версия, поверх которой правим; `null`
  /// означает создание.
  ///
  /// `PUT` заменяет урок целиком, поэтому [accent], [level] и [topicId] нужно
  /// передавать и при правке: без них сервер потерял бы категории урока.
  ///
  /// [isPublic] шлём, только если он задан; `null` — ключ не отправляем и
  /// публичность определяет сервер (admin — публичен). Значение решает
  /// контроллер по роли автора.
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
        // Тему не выбрали — ключ не отправляем вовсе: сервер сам поставит
        // «Other». Отправить `null` значило бы попросить его стереть тему.
        'topic_id': ?topicId,
        // Публичность шлём только когда автор ей управляет (owner); иначе
        // ключ не отправляем и решает сервер.
        'is_public': ?isPublic,
        'segments': [for (final segment in segments) segment.toJson()],
      },
      // Правка без `If-Match` — всегда конфликт: сервер не даст перезаписать
      // урок вслепую. При создании заголовка нет, урока ещё не существует.
      options: version == null
          ? null
          : Options(headers: {'If-Match': '"$version"'}),
    );
    return LessonDto.fromJson(response.data!);
  }

  @override
  Future<void> deleteLesson(String id) => _client.delete('/v1/lessons/$id');
}

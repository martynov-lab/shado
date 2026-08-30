import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/folder_dto.dart';

/// Страница списка папок.
class FolderPage {
  const FolderPage({required this.items, this.nextCursor});

  final List<FolderDto> items;

  /// `null` — страниц больше нет.
  final String? nextCursor;
}

/// Папки на сервере — источник истины (§6.2). UUID папки генерит клиент,
/// создание идёт `PUT`-ом (идемпотентно, как у уроков).
abstract interface class FolderRemoteDataSource {
  /// Список папок. Без [since] — только живые, с [since] — дельта с удалёнными.
  /// В списке у папки лишь `lesson_count`, без самих уроков.
  Future<FolderPage> list({String? since, int? limit, String? cursor});

  /// Папка целиком, с её уроками.
  Future<FolderDto> getFolder(String id);

  /// Создаёт ([version] == null) или правит папку. Правка требует `If-Match`
  /// с [version]; при устаревшей версии сервер отвечает `409`.
  Future<FolderDto> putFolder({
    required String id,
    required String title,
    required DateTime createdAt,
    int? version,
    bool? isPublic,
  });

  Future<void> deleteFolder(String id);

  /// Добавляет уроки в папку. Аддитивно и идемпотентно — `If-Match` не нужен.
  /// Возвращает обновлённую папку.
  Future<FolderDto> addLessons(String id, List<String> lessonIds);

  /// Убирает урок из папки (саму папку и урок не трогает).
  Future<void> removeLesson(String folderId, String lessonId);
}

class ApiFolderRemoteDataSource implements FolderRemoteDataSource {
  const ApiFolderRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<FolderPage> list({String? since, int? limit, String? cursor}) async {
    final json = await _client.get(
      '/v1/folders',
      query: {'since': ?since, 'limit': ?limit, 'cursor': ?cursor},
    );
    return FolderPage(
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          FolderDto.fromJson(item as Map<String, dynamic>),
      ],
      nextCursor: json['next_cursor'] as String?,
    );
  }

  @override
  Future<FolderDto> getFolder(String id) async {
    final json = await _client.get('/v1/folders/$id');
    return FolderDto.fromJson(json);
  }

  @override
  Future<FolderDto> putFolder({
    required String id,
    required String title,
    required DateTime createdAt,
    int? version,
    bool? isPublic,
  }) async {
    final response = await _client.put(
      '/v1/folders/$id',
      data: {
        'title': title,
        'created_at': createdAt.toUtc().toIso8601String(),
        // Публичность шлём только когда автор ей управляет (owner); иначе
        // ключ не отправляем и решает сервер.
        'is_public': ?isPublic,
      },
      // Создание идёт без `If-Match` — папки ещё нет; правка без него была бы
      // конфликтом.
      options: version == null
          ? null
          : Options(headers: {'If-Match': '"$version"'}),
    );
    return FolderDto.fromJson(response.data!);
  }

  @override
  Future<void> deleteFolder(String id) => _client.delete('/v1/folders/$id');

  @override
  Future<FolderDto> addLessons(String id, List<String> lessonIds) async {
    final response = await _client.post(
      '/v1/folders/$id/lessons',
      data: {'lesson_ids': lessonIds},
    );
    return FolderDto.fromJson(response.data!);
  }

  @override
  Future<void> removeLesson(String folderId, String lessonId) =>
      _client.delete('/v1/folders/$folderId/lessons/$lessonId');
}

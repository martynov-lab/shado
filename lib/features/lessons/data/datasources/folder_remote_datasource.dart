import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/folder_dto.dart';

/// A page of the folder list.
class FolderPage {
  const FolderPage({required this.items, this.nextCursor});

  final List<FolderDto> items;

  /// `null` when there are no more pages.
  final String? nextCursor;
}

/// Server-side folders; the client generates the UUID and creates via `PUT`.
abstract interface class FolderRemoteDataSource {
  /// Folder list; with [since] a delta arrives, deleted ones included.
  Future<FolderPage> list({String? since, int? limit, String? cursor});

  /// The whole folder with its lessons.
  Future<FolderDto> getFolder(String id);

  /// Creates or updates a folder; a `null` [version] means creation.
  Future<FolderDto> putFolder({
    required String id,
    required String title,
    required DateTime createdAt,
    int? version,
    bool? isPublic,
  });

  Future<void> deleteFolder(String id);

  /// Adds lessons to a folder and returns the updated folder.
  Future<FolderDto> addLessons(String id, List<String> lessonIds);

  /// Removes a lesson from a folder without touching the lesson.
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
        // Visibility is sent only when the author controls it.
        'is_public': ?isPublic,
      },
      // Edits carry `If-Match`, creation does not.
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

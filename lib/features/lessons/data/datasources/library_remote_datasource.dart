import '../../../../core/network/api_client.dart';
import '../models/folder_dto.dart';
import '../models/lesson_dto.dart';

/// Library root page: folders and lessons sharing one cursor.
class LibraryPage {
  const LibraryPage({
    this.folders = const [],
    this.lessons = const [],
    this.nextCursor,
  });

  final List<FolderDto> folders;
  final List<LessonDto> lessons;

  /// `null` when there are no more pages.
  final String? nextCursor;
}

/// Library root: folders and unfiled lessons in one request.
abstract interface class LibraryRemoteDataSource {
  Future<LibraryPage> list({int? limit, String? cursor});
}

class ApiLibraryRemoteDataSource implements LibraryRemoteDataSource {
  const ApiLibraryRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<LibraryPage> list({int? limit, String? cursor}) async {
    final json = await _client.get(
      '/v1/library',
      query: {'limit': ?limit, 'cursor': ?cursor},
    );

    final folders = <FolderDto>[];
    final lessons = <LessonDto>[];
    for (final raw in (json['items'] as List<dynamic>? ?? const [])) {
      final item = raw as Map<String, dynamic>;
      // Only `type` tells a folder from a lesson; unknown types are skipped.
      switch (item['type']) {
        case 'folder':
          folders.add(FolderDto.fromJson(item));
        case 'lesson':
          lessons.add(LessonDto.fromJson(item));
      }
    }

    return LibraryPage(
      folders: folders,
      lessons: lessons,
      nextCursor: json['next_cursor'] as String?,
    );
  }
}

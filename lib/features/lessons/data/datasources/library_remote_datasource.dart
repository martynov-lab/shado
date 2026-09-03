import '../../../../core/network/api_client.dart';
import '../models/folder_dto.dart';
import '../models/lesson_dto.dart';

/// Страница корня библиотеки: папки и уроки приходят вперемешку, а курсор у них
/// общий — на обе половины сразу.
class LibraryPage {
  const LibraryPage({
    this.folders = const [],
    this.lessons = const [],
    this.nextCursor,
  });

  final List<FolderDto> folders;
  final List<LessonDto> lessons;

  /// `null` — страниц больше нет.
  final String? nextCursor;
}

/// Лента главного экрана (§6.3): папки и уроки, которые ни в одной папке не
/// лежат, одним запросом.
///
/// `since` эндпоинт не поддерживает (отвечает `422`) — состав папки живёт
/// отдельно от урока и его `version` не поднимает, поэтому дельта по ленте была
/// бы неполной. Кеш наполняет `GET /v1/lessons?since=`, а корень всегда
/// сетевой.
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
      // Тело папки — как в `GET /v1/folders`, тело урока — как в
      // `GET /v1/lessons`; отличает их только `type`. Незнакомый тип пропускаем:
      // сервер вправе добавить свой, а экран от этого падать не должен.
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

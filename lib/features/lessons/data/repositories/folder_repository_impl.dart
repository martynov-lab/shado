import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/folder_remote_datasource.dart';
import '../datasources/lesson_local_datasource.dart';

/// Folders from the network; an opened folder is kept for offline starts,
/// with lessons taken from the lesson cache.
class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl({
    required FolderRemoteDataSource remoteDataSource,
    required LessonLocalDataSource localDataSource,
    Uuid uuid = const Uuid(),
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _uuid = uuid;

  /// Folder list page size.
  static const int _pageLimit = 100;

  final FolderRemoteDataSource _remote;
  final LessonLocalDataSource _local;
  final Uuid _uuid;

  @override
  Future<List<Folder>> getFolders() async {
    final folders = <Folder>[];
    String? cursor;
    do {
      // Without `since` the server returns live folders only.
      final page = await _remote.list(limit: _pageLimit, cursor: cursor);
      for (final dto in page.items) {
        folders.add(dto.toEntity());
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return folders;
  }

  @override
  Future<Folder> getFolder(String id) async {
    try {
      final folder = (await _remote.getFolder(id)).toEntity();
      await _local.writeFolder(folder);
      return folder;
    } on NetworkFailure {
      final cached = await _cachedFolder(id);
      if (cached == null) rethrow;
      return cached;
    }
  }

  @override
  Future<Folder> createFolder({
    required String title,
    bool? isPublic,
  }) async {
    final dto = await _remote.putFolder(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now().toUtc(),
      isPublic: isPublic,
    );
    return dto.toEntity();
  }

  @override
  Future<Folder> updateFolder({
    required String id,
    required String title,
    required int version,
    bool? isPublic,
  }) async {
    final dto = await _remote.putFolder(
      id: id,
      title: title,
      // `PUT` needs the field, but the server keeps the original date.
      createdAt: DateTime.now().toUtc(),
      version: version,
      isPublic: isPublic,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _remote.deleteFolder(id);
    await _local.deleteFolder(id);
  }

  @override
  Future<Folder> addLessons(String folderId, List<String> lessonIds) async {
    final dto = await _remote.addLessons(folderId, lessonIds);
    return dto.toEntity();
  }

  @override
  Future<Folder> removeLesson(String folderId, String lessonId) async {
    await _remote.removeLesson(folderId, lessonId);
    // Deletion answers `204` with no body — re-read the folder.
    final dto = await _remote.getFolder(folderId);
    return dto.toEntity();
  }

  /// The saved folder; lessons missing from the cache are skipped.
  Future<Folder?> _cachedFolder(String id) async {
    final saved = await _local.readFolder(id);
    if (saved == null) return null;
    final cached = {
      for (final model in await _local.getLessons()) model.id: model,
    };
    final folder = saved.folder;
    return Folder(
      id: folder.id,
      title: folder.title,
      createdAt: folder.createdAt,
      updatedAt: folder.updatedAt,
      version: folder.version,
      lessonCount: folder.lessonCount,
      isPublic: folder.isPublic,
      language: folder.language,
      lessons: [
        for (final lessonId in saved.lessonIds) ?cached[lessonId]?.toEntity(),
      ],
    );
  }
}

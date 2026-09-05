import 'package:uuid/uuid.dart';

import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/folder_remote_datasource.dart';

/// Folders; network only, there is no local cache.
class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl({
    required FolderRemoteDataSource remoteDataSource,
    Uuid uuid = const Uuid(),
  }) : _remote = remoteDataSource,
       _uuid = uuid;

  /// Folder list page size.
  static const int _pageLimit = 100;

  final FolderRemoteDataSource _remote;
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
    final dto = await _remote.getFolder(id);
    return dto.toEntity();
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
  Future<void> deleteFolder(String id) => _remote.deleteFolder(id);

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
}

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/library_root.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_datasource.dart';

/// Library root; network only, there is no local cache.
class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl({
    required LibraryRemoteDataSource remoteDataSource,
  }) : _remote = remoteDataSource;

  /// Library feed page size.
  static const int _pageLimit = 100;

  final LibraryRemoteDataSource _remote;

  @override
  Future<LibraryRoot> getRoot() async {
    final folders = <Folder>[];
    final lessons = <Lesson>[];
    String? cursor;
    do {
      final page = await _remote.list(limit: _pageLimit, cursor: cursor);
      for (final dto in page.folders) {
        folders.add(dto.toEntity());
      }
      for (final dto in page.lessons) {
        // The lesson screen downloads the file, so `audioPath` is empty here.
        lessons.add(dto.toEntity(audioPath: ''));
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return LibraryRoot(folders: folders, lessons: lessons);
  }
}

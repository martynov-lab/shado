import '../../../../core/error/failures.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/library_root.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/lesson_local_datasource.dart';
import '../datasources/library_remote_datasource.dart';

/// Library root from the network; its last copy is kept for offline starts,
/// with lessons taken from the lesson cache.
class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl({
    required LibraryRemoteDataSource remoteDataSource,
    required LessonLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  /// Library feed page size.
  static const int _pageLimit = 100;

  final LibraryRemoteDataSource _remote;
  final LessonLocalDataSource _local;

  @override
  Future<LibraryRoot> getRoot() async {
    try {
      final root = await _fetchRoot();
      await _local.writeLibrary(
        folders: root.folders,
        lessonIds: [for (final lesson in root.lessons) lesson.id],
      );
      return root;
    } on NetworkFailure {
      final cached = await _cachedRoot();
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<LibraryRoot> _fetchRoot() async {
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

  /// The saved root; lessons missing from the cache are skipped.
  Future<LibraryRoot?> _cachedRoot() async {
    final saved = await _local.readLibrary();
    if (saved == null) return null;
    final cached = {
      for (final model in await _local.getLessons()) model.id: model,
    };
    return LibraryRoot(
      folders: saved.folders,
      lessons: [for (final id in saved.lessonIds) ?cached[id]?.toEntity()],
    );
  }
}

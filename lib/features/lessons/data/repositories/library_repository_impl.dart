import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/library_root.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_datasource.dart';

/// Корень библиотеки: сервер — источник истины, локального кеша нет. Разложены
/// ли уроки по папкам, знает только он, а `since` лента не поддерживает (§6.3).
class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl({
    required LibraryRemoteDataSource remoteDataSource,
  }) : _remote = remoteDataSource;

  /// Размер страницы. Сервер отдаёт максимум 200 за раз.
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
        // Аудио здесь не нужно: это список для открытия, а файл докачает уже
        // экран урока — поэтому `audioPath` пустой.
        lessons.add(dto.toEntity(audioPath: ''));
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return LibraryRoot(folders: folders, lessons: lessons);
  }
}

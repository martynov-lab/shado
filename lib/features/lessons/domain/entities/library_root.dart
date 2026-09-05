import 'folder.dart';
import 'lesson.dart';

/// Library root: folders and unfiled lessons.
class LibraryRoot {
  const LibraryRoot({this.folders = const [], this.lessons = const []});

  static const LibraryRoot empty = LibraryRoot();

  /// Folders without nested lessons — only [Folder.lessonCount].
  final List<Folder> folders;

  /// Unfiled lessons ordered by `updated_at desc`.
  final List<Lesson> lessons;

  /// Neither folders nor lessons.
  bool get isEmpty => folders.isEmpty && lessons.isEmpty;
}

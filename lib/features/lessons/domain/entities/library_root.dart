import 'folder.dart';
import 'lesson.dart';

/// Корень библиотеки: папки и уроки, которые ни в одной папке не лежат (§6.3).
///
/// Сервер отдаёт обе половины одним запросом `GET /v1/library`, поэтому урок из
/// папки не успевает мелькнуть в общем списке. Скрыт из корня только тот урок,
/// который лежит в папке, **видимой зрителю**: чужая приватная папка урок не
/// прячет.
class LibraryRoot {
  const LibraryRoot({this.folders = const [], this.lessons = const []});

  static const LibraryRoot empty = LibraryRoot();

  /// Папки без вложенных уроков — только с [Folder.lessonCount].
  final List<Folder> folders;

  /// Уроки вне папок, в порядке `updated_at desc`.
  final List<Lesson> lessons;

  /// В библиотеке нет ничего — ни папок, ни свободных уроков.
  bool get isEmpty => folders.isEmpty && lessons.isEmpty;
}

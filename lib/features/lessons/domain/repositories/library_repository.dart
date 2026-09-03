import '../entities/library_root.dart';

/// Лента главного экрана (§6.3). Сервер собирает корень сам, поэтому локального
/// кеша у него нет: где какой урок лежит, знает только он.
abstract interface class LibraryRepository {
  /// Корень библиотеки: папки и уроки вне папок одним запросом.
  Future<LibraryRoot> getRoot();
}

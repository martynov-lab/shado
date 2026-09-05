import '../entities/library_root.dart';

/// Home feed; assembled by the server, there is no local cache.
abstract interface class LibraryRepository {
  /// Library root: folders and unfiled lessons in one request.
  Future<LibraryRoot> getRoot();
}

import '../entities/library_root.dart';
import '../repositories/library_repository.dart';

/// Library root for the home screen: folders and unfiled lessons.
class GetLibrary {
  const GetLibrary(this._repository);

  final LibraryRepository _repository;

  Future<LibraryRoot> call() => _repository.getRoot();
}

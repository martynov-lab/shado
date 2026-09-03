import '../entities/library_root.dart';
import '../repositories/library_repository.dart';

/// Корень библиотеки для главного экрана: папки и уроки вне папок.
class GetLibrary {
  const GetLibrary(this._repository);

  final LibraryRepository _repository;

  Future<LibraryRoot> call() => _repository.getRoot();
}

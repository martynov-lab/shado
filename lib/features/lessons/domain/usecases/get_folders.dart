import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Список папок для главного экрана.
class GetFolders {
  const GetFolders(this._repository);

  final FolderRepository _repository;

  Future<List<Folder>> call() => _repository.getFolders();
}

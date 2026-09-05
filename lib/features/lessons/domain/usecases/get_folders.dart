import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Folder list for the home screen.
class GetFolders {
  const GetFolders(this._repository);

  final FolderRepository _repository;

  Future<List<Folder>> call() => _repository.getFolders();
}

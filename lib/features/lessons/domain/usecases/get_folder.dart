import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// The whole folder with its lessons.
class GetFolder {
  const GetFolder(this._repository);

  final FolderRepository _repository;

  Future<Folder> call(String id) => _repository.getFolder(id);
}

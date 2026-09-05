import '../repositories/folder_repository.dart';

/// Folder deletion; the lessons stay in the catalog.
class DeleteFolder {
  const DeleteFolder(this._repository);

  final FolderRepository _repository;

  Future<void> call(String id) => _repository.deleteFolder(id);
}

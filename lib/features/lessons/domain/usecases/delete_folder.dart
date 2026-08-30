import '../repositories/folder_repository.dart';

/// Удаление папки. Уроки при этом не трогаются — снимается лишь группировка.
class DeleteFolder {
  const DeleteFolder(this._repository);

  final FolderRepository _repository;

  Future<void> call(String id) => _repository.deleteFolder(id);
}

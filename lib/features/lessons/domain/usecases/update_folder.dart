import '../../../../core/error/failures.dart';
import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Updates a folder title and visibility on top of its version.
class UpdateFolder {
  const UpdateFolder(this._repository);

  final FolderRepository _repository;

  Future<Folder> call({
    required String id,
    required String title,
    required int version,
    bool? isPublic,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('Введите название папки');
    }
    return _repository.updateFolder(
      id: id,
      title: trimmed,
      version: version,
      isPublic: isPublic,
    );
  }
}

import '../../../../core/error/failures.dart';
import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Folder creation: validates the title and passes it to the repository.
class CreateFolder {
  const CreateFolder(this._repository);

  final FolderRepository _repository;

  Future<Folder> call({required String title, bool? isPublic}) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('Введите название папки');
    }
    return _repository.createFolder(title: trimmed, isPublic: isPublic);
  }
}

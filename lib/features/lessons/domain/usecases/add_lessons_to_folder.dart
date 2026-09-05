import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Adds lessons to a folder; adding one twice is not an error.
class AddLessonsToFolder {
  const AddLessonsToFolder(this._repository);

  final FolderRepository _repository;

  Future<Folder> call({
    required String folderId,
    required List<String> lessonIds,
  }) => _repository.addLessons(folderId, lessonIds);
}

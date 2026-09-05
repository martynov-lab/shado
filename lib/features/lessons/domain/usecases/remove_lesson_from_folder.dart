import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Removes a lesson from a folder; the lesson stays in the catalog.
class RemoveLessonFromFolder {
  const RemoveLessonFromFolder(this._repository);

  final FolderRepository _repository;

  Future<Folder> call({
    required String folderId,
    required String lessonId,
  }) => _repository.removeLesson(folderId, lessonId);
}

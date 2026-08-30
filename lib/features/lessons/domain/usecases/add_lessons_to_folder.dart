import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Добавление уроков в папку. Повторное добавление того же урока — не ошибка.
class AddLessonsToFolder {
  const AddLessonsToFolder(this._repository);

  final FolderRepository _repository;

  Future<Folder> call({
    required String folderId,
    required List<String> lessonIds,
  }) => _repository.addLessons(folderId, lessonIds);
}

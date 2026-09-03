import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/folder.dart';
import 'folder_providers.dart';
import 'library_controller.dart';

/// Экран одной папки: её уроки и правка (для автора). Данные тянутся по сети,
/// а состав меняется точечными вызовами, после которых сервер возвращает
/// свежую папку.
class FolderDetailController extends AsyncNotifier<Folder> {
  FolderDetailController(this.folderId);

  final String folderId;

  @override
  Future<Folder> build() => ref.read(getFolderProvider)(folderId);

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(getFolderProvider)(folderId));
  }

  /// Переименовывает папку поверх её версии. `409` уходит наверх — страница
  /// покажет «изменена на другом устройстве».
  Future<void> rename(String title) async {
    final current = state.value;
    if (current == null) return;
    final updated = await ref.read(updateFolderProvider)(
      id: folderId,
      title: title,
      version: current.version,
    );
    state = AsyncData(updated);
  }

  /// Меняет видимость папки (только для owner).
  Future<void> setPrivate(bool isPrivate) async {
    final current = state.value;
    if (current == null) return;
    final updated = await ref.read(updateFolderProvider)(
      id: folderId,
      title: current.title,
      version: current.version,
      isPublic: !isPrivate,
    );
    state = AsyncData(updated);
  }

  Future<void> addLessons(List<String> lessonIds) async {
    if (lessonIds.isEmpty) return;
    final updated = await ref.read(addLessonsToFolderProvider)(
      folderId: folderId,
      lessonIds: lessonIds,
    );
    state = AsyncData(updated);
    _syncCatalog();
  }

  Future<void> removeLesson(String lessonId) async {
    final updated = await ref.read(removeLessonFromFolderProvider)(
      folderId: folderId,
      lessonId: lessonId,
    );
    state = AsyncData(updated);
    _syncCatalog();
  }

  Future<void> deleteFolder() async {
    await ref.read(deleteFolderProvider)(folderId);
    _syncCatalog();
  }

  /// Состав папки изменился — корень библиотеки надо перечитать: какие уроки
  /// теперь лежат в папках, а какие снова видны в каталоге, решает сервер.
  void _syncCatalog() => ref.invalidate(libraryControllerProvider);
}

final folderDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<FolderDetailController, Folder, String>(
      FolderDetailController.new,
    );

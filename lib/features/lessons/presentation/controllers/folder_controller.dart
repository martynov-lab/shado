import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/folder.dart';
import 'folder_providers.dart';
import 'library_controller.dart';

/// A single folder screen: its lessons, contents and metadata.
class FolderDetailController extends AsyncNotifier<Folder> {
  FolderDetailController(this.folderId);

  final String folderId;

  @override
  Future<Folder> build() => ref.read(getFolderProvider)(folderId);

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(getFolderProvider)(folderId));
  }

  /// Renames a folder on top of its version; conflicts bubble up.
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

  /// Changes folder visibility.
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

  /// Re-reads the library root after the folder contents change.
  void _syncCatalog() => ref.invalidate(libraryControllerProvider);
}

final folderDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<FolderDetailController, Folder, String>(
      FolderDetailController.new,
    );

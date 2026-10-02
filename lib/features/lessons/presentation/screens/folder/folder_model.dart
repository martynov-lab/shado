import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/folder_providers.dart';
import 'package:shado/di/lesson_providers.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/domain/services/auth_service.dart';
import '../../../domain/entities/folder.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/services/lesson_catalog_service.dart';
import '../../../domain/usecases/add_lessons_to_folder.dart';
import '../../../domain/usecases/delete_folder.dart';
import '../../../domain/usecases/get_folder.dart';
import '../../../domain/usecases/remove_lesson_from_folder.dart';
import '../../../domain/usecases/update_folder.dart';

/// Data and actions of one folder. Every change re-reads the library root so
/// the lessons screen stays in step.
class FolderModel extends ElementaryModel {
  FolderModel(ProviderContainer container, this.folderId)
    : _auth = container.read(authServiceProvider),
      _catalog = container.read(lessonCatalogServiceProvider),
      _getFolder = container.read(getFolderProvider),
      _updateFolder = container.read(updateFolderProvider),
      _addLessons = container.read(addLessonsToFolderProvider),
      _removeLesson = container.read(removeLessonFromFolderProvider),
      _deleteFolder = container.read(deleteFolderProvider);

  final String folderId;
  final AuthService _auth;
  final LessonCatalogService _catalog;
  final GetFolder _getFolder;
  final UpdateFolder _updateFolder;
  final AddLessonsToFolder _addLessons;
  final RemoveLessonFromFolder _removeLesson;
  final DeleteFolder _deleteFolder;

  late final StreamValueNotifier<UserRole?> _role = StreamValueNotifier(
    _auth.session.user?.role,
    _auth.changes.map((session) => session.user?.role),
  );

  ValueListenable<UserRole?> get role => _role;

  /// Unfiled lessons of the library root: the ones that can be added here.
  List<Lesson> get unfiledLessons => _catalog.library?.lessons ?? const [];

  Future<Folder> loadFolder() => _getFolder(folderId);

  /// Saves on top of [folder]'s version; a conflict is thrown.
  Future<Folder> rename(Folder folder, String title) =>
      _updateFolder(id: folderId, title: title, version: folder.version);

  Future<Folder> addLessons(List<String> lessonIds) async {
    final folder = await _addLessons(folderId: folderId, lessonIds: lessonIds);
    _catalog.refreshLibrary().ignore();
    return folder;
  }

  Future<Folder> removeLesson(String lessonId) async {
    final folder = await _removeLesson(folderId: folderId, lessonId: lessonId);
    _catalog.refreshLibrary().ignore();
    return folder;
  }

  Future<void> deleteFolder() async {
    await _deleteFolder(folderId);
    _catalog.refreshLibrary().ignore();
  }

  @override
  void dispose() {
    _role.dispose();
    super.dispose();
  }
}

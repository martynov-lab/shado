import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/library_root.dart';
import 'folder_providers.dart';
import 'lesson_providers.dart';
import 'library_providers.dart';

/// Library root: folders and unfiled lessons in one request.
class LibraryController extends AsyncNotifier<LibraryRoot> {
  @override
  Future<LibraryRoot> build() => _load();

  Future<LibraryRoot> _load() async {
    try {
      return await ref.read(getLibraryProvider)();
    } on NetworkFailure {
      // Offline the catalog cache is shown as a flat list.
      return LibraryRoot(lessons: await ref.read(getLessonsProvider)());
    }
  }

  /// Pull-to-refresh: re-reads the root.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Creates a folder and refreshes the root; the author role sets visibility.
  Future<Folder> create(String title) async {
    final folder = await ref.read(createFolderProvider)(
      title: title,
      isPublic: _isPublicForRole(),
    );
    await refresh();
    return folder;
  }

  bool? _isPublicForRole() {
    final role = ref.read(authControllerProvider).user?.role;
    return switch (role) {
      UserRole.owner => true,
      UserRole.userPro => false,
      _ => null,
    };
  }
}

final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, LibraryRoot>(
      LibraryController.new,
    );

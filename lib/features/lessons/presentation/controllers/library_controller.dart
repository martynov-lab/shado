import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/library_root.dart';
import 'folder_providers.dart';
import 'lesson_providers.dart';
import 'library_providers.dart';

/// Корень библиотеки для главного экрана: папки и уроки вне папок одним
/// запросом (§6.3).
///
/// Собирать корень на клиенте из `/v1/lessons` и `/v1/folders` больше не нужно:
/// какие уроки разложены по папкам, знает только сервер. `since` лента не
/// поддерживает, поэтому она всегда сетевая, а кеш уроков — запасной путь.
class LibraryController extends AsyncNotifier<LibraryRoot> {
  @override
  Future<LibraryRoot> build() => _load();

  Future<LibraryRoot> _load() async {
    try {
      return await ref.read(getLibraryProvider)();
    } on NetworkFailure {
      // Нет связи — показываем кеш каталога плоским списком: группировку по
      // папкам без сервера не восстановить, но уроки открываются как раньше.
      return LibraryRoot(lessons: await ref.read(getLessonsProvider)());
    }
  }

  /// Pull-to-refresh: перечитывает корень.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Создаёт папку и обновляет корень. Видимость определяется ролью автора,
  /// как у уроков: owner решает сам (по умолчанию публичная), user-pro всегда
  /// приватна, для admin решает сервер.
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

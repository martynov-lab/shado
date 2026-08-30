import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/folder.dart';
import 'folder_providers.dart';

/// Список папок для главного экрана. Сервер — источник истины, поэтому список
/// тянется по сети; сетевой сбой не роняет экран уроков — папки просто пусты.
class FoldersController extends AsyncNotifier<List<Folder>> {
  @override
  Future<List<Folder>> build() => _load();

  Future<List<Folder>> _load() async {
    try {
      return await ref.read(getFoldersProvider)();
    } on NetworkFailure {
      // Нет связи — папок не показываем, но список уроков продолжает работать.
      return const [];
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Создаёт папку и обновляет список. Видимость определяется ролью автора,
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

  Future<void> delete(String id) async {
    await ref.read(deleteFolderProvider)(id);
    await refresh();
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

final foldersControllerProvider =
    AsyncNotifierProvider<FoldersController, List<Folder>>(
      FoldersController.new,
    );

/// Идентификаторы уроков, уже разложенных по папкам: их убираем из общего
/// списка, чтобы урок жил либо в каталоге, либо в своей папке, но не в двух
/// местах сразу.
///
/// Состав папки виден только в её деталях (`GET /v1/folders/{id}`), поэтому для
/// непустых папок докачиваем детали. Папки обычно немногочисленны; провайдер
/// кеширует результат и пересчитывает его, когда список папок меняется или его
/// инвалидируют после правки состава.
final folderedLessonIdsProvider = FutureProvider<Set<String>>((ref) async {
  final folders =
      ref.watch(foldersControllerProvider).value ?? const <Folder>[];
  final getFolder = ref.watch(getFolderProvider);
  final ids = <String>{};
  for (final folder in folders) {
    if (folder.lessonCount == 0) continue;
    try {
      final full = await getFolder(folder.id);
      ids.addAll(full.lessons.map((lesson) => lesson.id));
    } catch (_) {
      // Не смогли прочитать одну папку — не прячем из-за этого весь список.
    }
  }
  return ids;
});

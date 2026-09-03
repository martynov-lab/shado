import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_providers.dart';
import 'library_controller.dart';

/// Список уроков для главного экрана.
///
/// Показываем кеш, а свежесть подтягиваем дельтой: так список появляется сразу,
/// даже когда сеть медленная или её нет вовсе.
class LessonsController extends AsyncNotifier<List<Lesson>> {
  @override
  Future<List<Lesson>> build() async {
    await _sync();
    return ref.read(getLessonsProvider)();
  }

  /// Тянет изменения с сервера. Сетевой сбой не прячет уже известные уроки:
  /// без связи приложение продолжает работать с тем, что скачано.
  Future<void> _sync() async {
    try {
      await ref.read(syncLessonsProvider)();
    } on NetworkFailure {
      // Кеша достаточно, чтобы показать список.
    }
  }

  /// Pull-to-refresh: перечитывает дельту и обновляет список.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      await ref.read(syncLessonsProvider)();
      return ref.read(getLessonsProvider)();
    });
  }

  /// Локальное обновление без похода на сервер — после создания или правки.
  Future<void> reloadFromCache() async {
    state = await AsyncValue.guard(() => ref.read(getLessonsProvider)());
  }

  Future<void> delete(String lessonId) async {
    await ref.read(deleteLessonProvider)(lessonId);
    await reloadFromCache();
    // Урок исчез и из корня библиотеки — его собирает сервер, поэтому просто
    // перечитываем ленту.
    ref.invalidate(libraryControllerProvider);
  }
}

final lessonsControllerProvider =
    AsyncNotifierProvider<LessonsController, List<Lesson>>(
      LessonsController.new,
    );

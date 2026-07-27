import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lesson.dart';
import 'lesson_providers.dart';

/// Список уроков для главного экрана.
class LessonsController extends AsyncNotifier<List<Lesson>> {
  @override
  Future<List<Lesson>> build() => ref.watch(getLessonsProvider)();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(getLessonsProvider)());
  }

  Future<void> delete(String lessonId) async {
    await ref.read(deleteLessonProvider)(lessonId);
    await refresh();
  }
}

final lessonsControllerProvider =
    AsyncNotifierProvider<LessonsController, List<Lesson>>(
      LessonsController.new,
    );

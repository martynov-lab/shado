import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_providers.dart';
import 'library_controller.dart';

/// Lesson list: shows the cache and catches up with a delta.
class LessonsController extends AsyncNotifier<List<Lesson>> {
  @override
  Future<List<Lesson>> build() async {
    await _sync();
    return ref.read(getLessonsProvider)();
  }

  /// Pulls server changes; a network failure keeps known lessons visible.
  Future<void> _sync() async {
    try {
      await ref.read(syncLessonsProvider)();
    } on NetworkFailure {
      // The cache is enough to render the list.
    }
  }

  /// Pull-to-refresh: re-reads the delta and refreshes the list.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      await ref.read(syncLessonsProvider)();
      return ref.read(getLessonsProvider)();
    });
  }

  /// Re-reads the list from the cache without hitting the server.
  Future<void> reloadFromCache() async {
    state = await AsyncValue.guard(() => ref.read(getLessonsProvider)());
  }

  Future<void> delete(String lessonId) async {
    await ref.read(deleteLessonProvider)(lessonId);
    await reloadFromCache();
    // The server assembles the library root — re-read the feed.
    ref.invalidate(libraryControllerProvider);
  }
}

final lessonsControllerProvider =
    AsyncNotifierProvider<LessonsController, List<Lesson>>(
      LessonsController.new,
    );

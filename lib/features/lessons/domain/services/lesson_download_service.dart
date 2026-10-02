import 'dart:async';

import '../entities/lesson.dart';
import '../entities/lesson_download.dart';
import '../repositories/lesson_repository.dart';

/// Offline downloads of lessons shared by the list and lesson screens.
class LessonDownloadService {
  LessonDownloadService({
    required LessonRepository repository,
    required Stream<List<Lesson>> catalogChanges,
  }) : _repository = repository {
    _catalogSubscription = catalogChanges.listen((_) => unawaited(reload()));
  }

  final LessonRepository _repository;
  final StreamController<Map<String, LessonDownload>> _changes =
      StreamController.broadcast();
  late final StreamSubscription<List<Lesson>> _catalogSubscription;

  Map<String, LessonDownload> _downloads = const {};
  Future<void>? _loading;

  /// Lessons that are downloaded or downloading, by id.
  Map<String, LessonDownload> get downloads => _downloads;

  Stream<Map<String, LessonDownload>> get changes => _changes.stream;

  Set<String> get downloadedIds => {
    for (final MapEntry(:key, :value) in _downloads.entries)
      if (value is Downloaded) key,
  };

  LessonDownload stateOf(String lessonId) =>
      _downloads[lessonId] ?? const NotDownloaded();

  /// Reads the downloaded lessons once.
  Future<void> load() => _loading ??= reload();

  /// Re-reads the downloaded lessons after the cache changed; running
  /// downloads keep their progress.
  Future<void> reload() async {
    final ids = await _repository.downloadedLessonIds();
    _apply({
      for (final id in ids) id: const Downloaded(),
      for (final MapEntry(:key, :value) in _downloads.entries)
        if (value is Downloading) key: value,
    });
  }

  /// Errors are thrown as they are; the lesson is then not downloaded.
  Future<void> download(String lessonId) async {
    if (stateOf(lessonId) is! NotDownloaded) return;
    _set(lessonId, const Downloading());
    var percent = -1;
    try {
      await _repository.downloadLesson(
        lessonId,
        onProgress: (received, total) {
          if (total <= 0) return;
          // Whole percents only: the transfer reports every chunk.
          final next = received * 100 ~/ total;
          if (next == percent) return;
          percent = next;
          _set(lessonId, Downloading(next / 100));
        },
      );
      _set(lessonId, const Downloaded());
    } catch (_) {
      _set(lessonId, const NotDownloaded());
      rethrow;
    }
  }

  Future<void> remove(String lessonId) async {
    await _repository.removeDownload(lessonId);
    _set(lessonId, const NotDownloaded());
  }

  void dispose() {
    _catalogSubscription.cancel();
    _changes.close();
  }

  void _set(String lessonId, LessonDownload state) {
    final next = Map.of(_downloads);
    if (state is NotDownloaded) {
      next.remove(lessonId);
    } else {
      next[lessonId] = state;
    }
    _apply(next);
  }

  void _apply(Map<String, LessonDownload> downloads) {
    _downloads = Map.unmodifiable(downloads);
    _changes.add(_downloads);
  }
}

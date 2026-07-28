import 'package:uuid/uuid.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/audio_file_datasource.dart';
import '../datasources/lesson_local_datasource.dart';
import '../models/lesson_model.dart';

/// Сейчас поверх одного локального источника. Удалённый источник и логика
/// синхронизации появятся здесь же, не затрагивая domain и presentation.
class LessonRepositoryImpl implements LessonRepository {
  LessonRepositoryImpl({
    required LessonLocalDataSource localDataSource,
    required AudioFileDataSource audioDataSource,
    Uuid uuid = const Uuid(),
  }) : _local = localDataSource,
       _audio = audioDataSource,
       _uuid = uuid;

  final LessonLocalDataSource _local;
  final AudioFileDataSource _audio;
  final Uuid _uuid;

  @override
  Future<List<Lesson>> getLessons() async {
    final models = await _local.getLessons();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<Lesson?> getLesson(String id) async {
    final model = await _local.getLesson(id);
    return model?.toEntity();
  }

  @override
  Future<Lesson> createLesson({
    required String title,
    required String sourceAudioPath,
    required List<String> segmentTexts,
    List<int>? boundaries,
  }) async {
    // UUID, а не автоинкремент: идентификатор должен совпасть с серверным,
    // когда появится бэкенд.
    final id = _uuid.v4();
    final audioPath = await _audio.importAudio(
      lessonId: id,
      sourcePath: sourceAudioPath,
    );
    try {
      final durationMs = await _audio.resolveDurationMs(audioPath);
      var lesson = Lesson.withEvenBoundaries(
        id: id,
        title: title,
        audioPath: audioPath,
        durationMs: durationMs,
        createdAt: DateTime.now().toUtc(),
        segmentTexts: segmentTexts,
      );
      if (boundaries != null && boundaries.length == segmentTexts.length + 1) {
        lesson = lesson.withBoundaries(
          SegmentBoundaries.normalize(boundaries, durationMs),
        );
      }
      await _local.upsertLesson(LessonModel.fromEntity(lesson));
      return lesson;
    } catch (_) {
      // Урок не создался — не оставляем осиротевшую копию аудио.
      await _audio.deleteAudio(audioPath);
      rethrow;
    }
  }

  @override
  Future<int> resolveAudioDurationMs(String audioPath) =>
      _audio.resolveDurationMs(audioPath);

  @override
  Future<void> updateLesson(Lesson lesson) {
    return _local.upsertLesson(LessonModel.fromEntity(lesson));
  }

  @override
  Future<void> deleteLesson(String id) async {
    final model = await _local.getLesson(id);
    await _local.deleteLesson(id);
    if (model != null) {
      await _audio.deleteAudio(model.audioPath);
    }
  }
}

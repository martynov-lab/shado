import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/lesson.dart';
import 'lesson_dto.dart';
import 'segment_model.dart';

part 'lesson_model.freezed.dart';
part 'lesson_model.g.dart';

/// Урок в локальном кеше. Времена сериализуются в ISO-8601 UTC.
///
/// От серверного [LessonDto] отличается двумя вещами, ради которых кеш и нужен:
/// здесь лежит [audioPath] — путь к скачанному файлу, которого на сервере нет,
/// — и [version], с которой уходит следующая правка.
@freezed
abstract class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String title,
    @JsonKey(name: 'audio_id') required String audioId,

    /// Путь к скачанному файлу; пустая строка — файла ещё нет, урок докачает
    /// его при открытии.
    @JsonKey(name: 'audio_path') required String audioPath,
    @JsonKey(name: 'duration_ms') required int durationMs,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    required int version,
    required List<SegmentModel> segments,
    @JsonKey(name: 'audio_sha256') @Default('') String audioSha256,
    @JsonKey(name: 'audio_content_type') @Default('') String audioContentType,
  }) = _LessonModel;

  const LessonModel._();

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);

  /// Урок, пришедший с сервера, вместе с локальным путём к аудио.
  factory LessonModel.fromDto(LessonDto dto, {required String audioPath}) =>
      LessonModel(
        id: dto.id,
        title: dto.title,
        audioId: dto.audio.id,
        audioPath: audioPath,
        durationMs: dto.durationMs,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
        version: dto.version,
        segments: dto.segments,
        audioSha256: dto.audio.sha256,
        audioContentType: dto.audio.contentType,
      );

  bool get hasAudioFile => audioPath.isNotEmpty;

  Lesson toEntity() => Lesson(
    id: id,
    title: title,
    audioPath: audioPath,
    audioId: audioId,
    durationMs: durationMs,
    createdAt: createdAt.toUtc(),
    segments: segments.map((segment) => segment.toEntity()).toList(),
  );
}

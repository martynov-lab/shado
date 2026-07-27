import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/lesson.dart';
import 'segment_model.dart';

part 'lesson_model.freezed.dart';
part 'lesson_model.g.dart';

/// DTO урока. Времена сериализуются в ISO-8601 UTC.
@freezed
abstract class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String title,
    @JsonKey(name: 'audio_path') required String audioPath,
    @JsonKey(name: 'duration_ms') required int durationMs,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required List<SegmentModel> segments,
  }) = _LessonModel;

  const LessonModel._();

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);

  factory LessonModel.fromEntity(Lesson lesson) => LessonModel(
    id: lesson.id,
    title: lesson.title,
    audioPath: lesson.audioPath,
    durationMs: lesson.durationMs,
    createdAt: lesson.createdAt.toUtc(),
    segments: lesson.segments.map(SegmentModel.fromEntity).toList(),
  );

  Lesson toEntity() => Lesson(
    id: id,
    title: title,
    audioPath: audioPath,
    durationMs: durationMs,
    createdAt: createdAt.toUtc(),
    segments: segments.map((segment) => segment.toEntity()).toList(),
  );
}

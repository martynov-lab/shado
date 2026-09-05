import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import 'lesson_dto.dart';
import 'segment_model.dart';

part 'lesson_model.freezed.dart';
part 'lesson_model.g.dart';

/// Lesson in the local cache; times are serialized as ISO-8601 UTC.
@freezed
abstract class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String title,
    @JsonKey(name: 'audio_id') required String audioId,

    /// Path to the downloaded file; an empty string means it is missing.
    @JsonKey(name: 'audio_path') required String audioPath,
    @JsonKey(name: 'duration_ms') required int durationMs,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    required int version,
    required List<SegmentModel> segments,

    /// Lesson visibility; records without the field count as public.
    @JsonKey(name: 'is_public') @Default(true) bool isPublic,
    @JsonKey(name: 'audio_sha256') @Default('') String audioSha256,
    @JsonKey(name: 'audio_content_type') @Default('') String audioContentType,

    /// Lesson categories as strings from the server; empty means unset.
    @Default('') String accent,
    @Default('') String level,

    /// Lesson topic: id and name side by side.
    @JsonKey(name: 'topic_id') @Default('') String topicId,
    @JsonKey(name: 'topic_name') @Default('') String topicName,
  }) = _LessonModel;

  const LessonModel._();

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);

  /// A lesson from the server together with the local audio path.
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
        isPublic: dto.isPublic,
        audioSha256: dto.audio.sha256,
        audioContentType: dto.audio.contentType,
        accent: dto.accent?.wire ?? '',
        level: dto.level?.wire ?? '',
        topicId: dto.topic?.id ?? '',
        topicName: dto.topic?.name ?? '',
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
    isPublic: isPublic,
    accent: LessonAccent.parse(accent),
    level: LessonLevel.parse(level),
    topic: topicId.isEmpty ? null : Topic(id: topicId, name: topicName),
  );
}

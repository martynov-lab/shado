import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/lesson_kind.dart';
import 'lesson_dto.dart';
import 'phrase_model.dart';
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

    /// Language code of the lesson; empty in records from an old cache.
    @Default('') String language,

    /// Lesson categories as strings from the server; empty means unset.
    @Default('') String accent,
    @Default('') String level,

    /// Lesson topic: id and name side by side.
    @JsonKey(name: 'topic_id') @Default('') String topicId,
    @JsonKey(name: 'topic_name') @Default('') String topicName,

    /// `story` or `expressions`.
    @Default('story') String kind,

    /// Phrases of a phrase set; empty for a story.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<PhraseModel> phrases,
  }) = _LessonModel;

  const LessonModel._();

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);

  /// A lesson from the server together with the local audio paths: of the
  /// story or, for a phrase set, inside [phrases].
  factory LessonModel.fromDto(
    LessonDto dto, {
    required String audioPath,
    List<PhraseModel>? phrases,
  }) => LessonModel(
        id: dto.id,
        title: dto.title,
        audioId: dto.audio?.id ?? '',
        audioPath: audioPath,
        durationMs: dto.durationMs,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
        version: dto.version,
        segments: dto.segments,
        isPublic: dto.isPublic,
        audioSha256: dto.audio?.sha256 ?? '',
        audioContentType: dto.audio?.contentType ?? '',
        language: dto.language,
        accent: dto.accent ?? '',
        level: dto.level?.wire ?? '',
        topicId: dto.topic?.id ?? '',
        topicName: dto.topic?.name ?? '',
        kind: dto.kind.wire,
        phrases: phrases ?? dto.phrases,
      );

  bool get isExpressions => kind == LessonKind.expressions.wire;

  /// Whether every audio the lesson plays is on the device.
  bool get hasAudioFile => isExpressions
      ? phrases.every((phrase) => phrase.audioPath.isNotEmpty)
      : audioPath.isNotEmpty;

  /// Local paths of every audio the lesson plays.
  List<String> get audioPaths => isExpressions
      ? [for (final phrase in phrases) phrase.audioPath]
      : [audioPath];

  /// Ids of every audio the lesson plays.
  Set<String> get audioIds => isExpressions
      ? {for (final phrase in phrases) phrase.audio.id}
      : {audioId};

  Lesson toEntity() => Lesson(
    id: id,
    title: title,
    audioPath: audioPath,
    audioId: audioId,
    durationMs: durationMs,
    createdAt: createdAt.toUtc(),
    segments: segments.map((segment) => segment.toEntity()).toList(),
    isPublic: isPublic,
    language: language,
    accent: accent.isEmpty ? null : accent,
    level: LessonLevel.parse(level),
    topic: topicId.isEmpty ? null : Topic(id: topicId, name: topicName),
    kind: LessonKind.parse(kind),
    phrases: [for (final phrase in phrases) phrase.toEntity()],
  );
}

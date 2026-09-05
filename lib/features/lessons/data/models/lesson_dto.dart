import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import 'audio_dto.dart';
import 'segment_model.dart';

/// Lesson exactly as the server returns it.
class LessonDto {
  const LessonDto({
    required this.id,
    required this.title,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.audio,
    required this.segments,
    this.isPublic = true,
    this.deletedAt,
    this.accent,
    this.level,
    this.topic,
  });

  factory LessonDto.fromJson(Map<String, dynamic> json) => LessonDto(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    createdAt: _parseTime(json['created_at']),
    updatedAt: _parseTime(json['updated_at']),
    deletedAt: json['deleted_at'] == null
        ? null
        : _parseTime(json['deleted_at']),
    version: (json['version'] as num?)?.toInt() ?? 1,
    // Without the field the lesson counts as public.
    isPublic: json['is_public'] as bool? ?? true,
    accent: LessonAccent.parse(json['accent'] as String?),
    level: LessonLevel.parse(json['level'] as String?),
    // The topic arrives as a `{id, name}` object.
    topic: json['topic'] is Map
        ? Topic.fromJson(Map<String, dynamic>.from(json['topic'] as Map))
        : null,
    audio: AudioDto.fromJson(json['audio'] as Map<String, dynamic>),
    segments: [
      for (final segment in (json['segments'] as List<dynamic>? ?? const []))
        SegmentModel.fromJson(segment as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final int durationMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Deletion time; only present in a delta.
  final DateTime? deletedAt;

  /// Aggregate version; sent back in `If-Match` on edits.
  final int version;

  /// Lesson visibility; a private one is visible to its author only.
  final bool isPublic;

  /// Lesson categories; `null` when the server sent an empty or unknown value.
  final LessonAccent? accent;
  final LessonLevel? level;
  final Topic? topic;

  final AudioDto audio;
  final List<SegmentModel> segments;

  bool get isDeleted => deletedAt != null;

  /// Domain lesson; the repository fills in the downloaded audio path.
  Lesson toEntity({required String audioPath}) => Lesson(
    id: id,
    title: title,
    audioPath: audioPath,
    durationMs: durationMs,
    createdAt: createdAt,
    segments: segments.map((segment) => segment.toEntity()).toList(),
    isPublic: isPublic,
    accent: accent,
    level: level,
    topic: topic,
  );

  static DateTime _parseTime(Object? raw) =>
      DateTime.tryParse(raw as String? ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

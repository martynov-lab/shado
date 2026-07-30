// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonModel _$LessonModelFromJson(Map<String, dynamic> json) => _LessonModel(
  id: json['id'] as String,
  title: json['title'] as String,
  audioId: json['audio_id'] as String,
  audioPath: json['audio_path'] as String,
  durationMs: (json['duration_ms'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  version: (json['version'] as num).toInt(),
  segments: (json['segments'] as List<dynamic>)
      .map((e) => SegmentModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  audioSha256: json['audio_sha256'] as String? ?? '',
  audioContentType: json['audio_content_type'] as String? ?? '',
  accent: json['accent'] as String? ?? '',
  level: json['level'] as String? ?? '',
  topicId: json['topic_id'] as String? ?? '',
  topicName: json['topic_name'] as String? ?? '',
);

Map<String, dynamic> _$LessonModelToJson(_LessonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'audio_id': instance.audioId,
      'audio_path': instance.audioPath,
      'duration_ms': instance.durationMs,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'version': instance.version,
      'segments': instance.segments,
      'audio_sha256': instance.audioSha256,
      'audio_content_type': instance.audioContentType,
      'accent': instance.accent,
      'level': instance.level,
      'topic_id': instance.topicId,
      'topic_name': instance.topicName,
    };

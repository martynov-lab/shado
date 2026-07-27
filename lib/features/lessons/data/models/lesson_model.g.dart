// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonModel _$LessonModelFromJson(Map<String, dynamic> json) => _LessonModel(
  id: json['id'] as String,
  title: json['title'] as String,
  audioPath: json['audio_path'] as String,
  durationMs: (json['duration_ms'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  segments: (json['segments'] as List<dynamic>)
      .map((e) => SegmentModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LessonModelToJson(_LessonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'audio_path': instance.audioPath,
      'duration_ms': instance.durationMs,
      'created_at': instance.createdAt.toIso8601String(),
      'segments': instance.segments,
    };

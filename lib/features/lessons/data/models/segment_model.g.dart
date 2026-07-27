// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SegmentModel _$SegmentModelFromJson(Map<String, dynamic> json) =>
    _SegmentModel(
      index: (json['index'] as num).toInt(),
      text: json['text'] as String,
      startMs: (json['start_ms'] as num).toInt(),
      endMs: (json['end_ms'] as num).toInt(),
    );

Map<String, dynamic> _$SegmentModelToJson(_SegmentModel instance) =>
    <String, dynamic>{
      'index': instance.index,
      'text': instance.text,
      'start_ms': instance.startMs,
      'end_ms': instance.endMs,
    };

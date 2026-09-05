import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/segment.dart';

part 'segment_model.freezed.dart';
part 'segment_model.g.dart';

/// Lesson segment DTO; the JSON shape is shared by the server and the cache.
@freezed
abstract class SegmentModel with _$SegmentModel {
  const factory SegmentModel({
    required int index,
    required String text,
    @JsonKey(name: 'start_ms') required int startMs,
    @JsonKey(name: 'end_ms') required int endMs,
  }) = _SegmentModel;

  const SegmentModel._();

  factory SegmentModel.fromJson(Map<String, dynamic> json) =>
      _$SegmentModelFromJson(json);

  factory SegmentModel.fromEntity(Segment segment) => SegmentModel(
    index: segment.index,
    text: segment.text,
    startMs: segment.startMs,
    endMs: segment.endMs,
  );

  Segment toEntity() =>
      Segment(index: index, text: text, startMs: startMs, endMs: endMs);
}

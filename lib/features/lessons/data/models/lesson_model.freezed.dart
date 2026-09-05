// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LessonModel {

 String get id; String get title;@JsonKey(name: 'audio_id') String get audioId;/// Path to the downloaded file; an empty string means it is missing.
@JsonKey(name: 'audio_path') String get audioPath;@JsonKey(name: 'duration_ms') int get durationMs;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt; int get version; List<SegmentModel> get segments;/// Lesson visibility; records without the field count as public.
@JsonKey(name: 'is_public') bool get isPublic;@JsonKey(name: 'audio_sha256') String get audioSha256;@JsonKey(name: 'audio_content_type') String get audioContentType;/// Lesson categories as strings from the server; empty means unset.
 String get accent; String get level;/// Lesson topic: id and name side by side.
@JsonKey(name: 'topic_id') String get topicId;@JsonKey(name: 'topic_name') String get topicName;
/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonModelCopyWith<LessonModel> get copyWith => _$LessonModelCopyWithImpl<LessonModel>(this as LessonModel, _$identity);

  /// Serializes this LessonModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.audioId, audioId) || other.audioId == audioId)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.segments, segments)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.audioSha256, audioSha256) || other.audioSha256 == audioSha256)&&(identical(other.audioContentType, audioContentType) || other.audioContentType == audioContentType)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.level, level) || other.level == level)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.topicName, topicName) || other.topicName == topicName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,audioId,audioPath,durationMs,createdAt,updatedAt,version,const DeepCollectionEquality().hash(segments),isPublic,audioSha256,audioContentType,accent,level,topicId,topicName);

@override
String toString() {
  return 'LessonModel(id: $id, title: $title, audioId: $audioId, audioPath: $audioPath, durationMs: $durationMs, createdAt: $createdAt, updatedAt: $updatedAt, version: $version, segments: $segments, isPublic: $isPublic, audioSha256: $audioSha256, audioContentType: $audioContentType, accent: $accent, level: $level, topicId: $topicId, topicName: $topicName)';
}


}

/// @nodoc
abstract mixin class $LessonModelCopyWith<$Res>  {
  factory $LessonModelCopyWith(LessonModel value, $Res Function(LessonModel) _then) = _$LessonModelCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(name: 'audio_id') String audioId,@JsonKey(name: 'audio_path') String audioPath,@JsonKey(name: 'duration_ms') int durationMs,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, int version, List<SegmentModel> segments,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'audio_sha256') String audioSha256,@JsonKey(name: 'audio_content_type') String audioContentType, String accent, String level,@JsonKey(name: 'topic_id') String topicId,@JsonKey(name: 'topic_name') String topicName
});




}
/// @nodoc
class _$LessonModelCopyWithImpl<$Res>
    implements $LessonModelCopyWith<$Res> {
  _$LessonModelCopyWithImpl(this._self, this._then);

  final LessonModel _self;
  final $Res Function(LessonModel) _then;

/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? audioId = null,Object? audioPath = null,Object? durationMs = null,Object? createdAt = null,Object? updatedAt = null,Object? version = null,Object? segments = null,Object? isPublic = null,Object? audioSha256 = null,Object? audioContentType = null,Object? accent = null,Object? level = null,Object? topicId = null,Object? topicName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,audioId: null == audioId ? _self.audioId : audioId // ignore: cast_nullable_to_non_nullable
as String,audioPath: null == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<SegmentModel>,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,audioSha256: null == audioSha256 ? _self.audioSha256 : audioSha256 // ignore: cast_nullable_to_non_nullable
as String,audioContentType: null == audioContentType ? _self.audioContentType : audioContentType // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,topicId: null == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String,topicName: null == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonModel].
extension LessonModelPatterns on LessonModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonModel value)  $default,){
final _that = this;
switch (_that) {
case _LessonModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonModel value)?  $default,){
final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'audio_id')  String audioId, @JsonKey(name: 'audio_path')  String audioPath, @JsonKey(name: 'duration_ms')  int durationMs, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  int version,  List<SegmentModel> segments, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'audio_sha256')  String audioSha256, @JsonKey(name: 'audio_content_type')  String audioContentType,  String accent,  String level, @JsonKey(name: 'topic_id')  String topicId, @JsonKey(name: 'topic_name')  String topicName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
return $default(_that.id,_that.title,_that.audioId,_that.audioPath,_that.durationMs,_that.createdAt,_that.updatedAt,_that.version,_that.segments,_that.isPublic,_that.audioSha256,_that.audioContentType,_that.accent,_that.level,_that.topicId,_that.topicName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'audio_id')  String audioId, @JsonKey(name: 'audio_path')  String audioPath, @JsonKey(name: 'duration_ms')  int durationMs, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  int version,  List<SegmentModel> segments, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'audio_sha256')  String audioSha256, @JsonKey(name: 'audio_content_type')  String audioContentType,  String accent,  String level, @JsonKey(name: 'topic_id')  String topicId, @JsonKey(name: 'topic_name')  String topicName)  $default,) {final _that = this;
switch (_that) {
case _LessonModel():
return $default(_that.id,_that.title,_that.audioId,_that.audioPath,_that.durationMs,_that.createdAt,_that.updatedAt,_that.version,_that.segments,_that.isPublic,_that.audioSha256,_that.audioContentType,_that.accent,_that.level,_that.topicId,_that.topicName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(name: 'audio_id')  String audioId, @JsonKey(name: 'audio_path')  String audioPath, @JsonKey(name: 'duration_ms')  int durationMs, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  int version,  List<SegmentModel> segments, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'audio_sha256')  String audioSha256, @JsonKey(name: 'audio_content_type')  String audioContentType,  String accent,  String level, @JsonKey(name: 'topic_id')  String topicId, @JsonKey(name: 'topic_name')  String topicName)?  $default,) {final _that = this;
switch (_that) {
case _LessonModel() when $default != null:
return $default(_that.id,_that.title,_that.audioId,_that.audioPath,_that.durationMs,_that.createdAt,_that.updatedAt,_that.version,_that.segments,_that.isPublic,_that.audioSha256,_that.audioContentType,_that.accent,_that.level,_that.topicId,_that.topicName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonModel extends LessonModel {
  const _LessonModel({required this.id, required this.title, @JsonKey(name: 'audio_id') required this.audioId, @JsonKey(name: 'audio_path') required this.audioPath, @JsonKey(name: 'duration_ms') required this.durationMs, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, required this.version, required final  List<SegmentModel> segments, @JsonKey(name: 'is_public') this.isPublic = true, @JsonKey(name: 'audio_sha256') this.audioSha256 = '', @JsonKey(name: 'audio_content_type') this.audioContentType = '', this.accent = '', this.level = '', @JsonKey(name: 'topic_id') this.topicId = '', @JsonKey(name: 'topic_name') this.topicName = ''}): _segments = segments,super._();
  factory _LessonModel.fromJson(Map<String, dynamic> json) => _$LessonModelFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey(name: 'audio_id') final  String audioId;
/// Path to the downloaded file; an empty string means it is missing.
@override@JsonKey(name: 'audio_path') final  String audioPath;
@override@JsonKey(name: 'duration_ms') final  int durationMs;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override final  int version;
 final  List<SegmentModel> _segments;
@override List<SegmentModel> get segments {
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segments);
}

/// Lesson visibility; records without the field count as public.
@override@JsonKey(name: 'is_public') final  bool isPublic;
@override@JsonKey(name: 'audio_sha256') final  String audioSha256;
@override@JsonKey(name: 'audio_content_type') final  String audioContentType;
/// Lesson categories as strings from the server; empty means unset.
@override@JsonKey() final  String accent;
@override@JsonKey() final  String level;
/// Lesson topic: id and name side by side.
@override@JsonKey(name: 'topic_id') final  String topicId;
@override@JsonKey(name: 'topic_name') final  String topicName;

/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonModelCopyWith<_LessonModel> get copyWith => __$LessonModelCopyWithImpl<_LessonModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.audioId, audioId) || other.audioId == audioId)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._segments, _segments)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.audioSha256, audioSha256) || other.audioSha256 == audioSha256)&&(identical(other.audioContentType, audioContentType) || other.audioContentType == audioContentType)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.level, level) || other.level == level)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.topicName, topicName) || other.topicName == topicName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,audioId,audioPath,durationMs,createdAt,updatedAt,version,const DeepCollectionEquality().hash(_segments),isPublic,audioSha256,audioContentType,accent,level,topicId,topicName);

@override
String toString() {
  return 'LessonModel(id: $id, title: $title, audioId: $audioId, audioPath: $audioPath, durationMs: $durationMs, createdAt: $createdAt, updatedAt: $updatedAt, version: $version, segments: $segments, isPublic: $isPublic, audioSha256: $audioSha256, audioContentType: $audioContentType, accent: $accent, level: $level, topicId: $topicId, topicName: $topicName)';
}


}

/// @nodoc
abstract mixin class _$LessonModelCopyWith<$Res> implements $LessonModelCopyWith<$Res> {
  factory _$LessonModelCopyWith(_LessonModel value, $Res Function(_LessonModel) _then) = __$LessonModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(name: 'audio_id') String audioId,@JsonKey(name: 'audio_path') String audioPath,@JsonKey(name: 'duration_ms') int durationMs,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, int version, List<SegmentModel> segments,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'audio_sha256') String audioSha256,@JsonKey(name: 'audio_content_type') String audioContentType, String accent, String level,@JsonKey(name: 'topic_id') String topicId,@JsonKey(name: 'topic_name') String topicName
});




}
/// @nodoc
class __$LessonModelCopyWithImpl<$Res>
    implements _$LessonModelCopyWith<$Res> {
  __$LessonModelCopyWithImpl(this._self, this._then);

  final _LessonModel _self;
  final $Res Function(_LessonModel) _then;

/// Create a copy of LessonModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? audioId = null,Object? audioPath = null,Object? durationMs = null,Object? createdAt = null,Object? updatedAt = null,Object? version = null,Object? segments = null,Object? isPublic = null,Object? audioSha256 = null,Object? audioContentType = null,Object? accent = null,Object? level = null,Object? topicId = null,Object? topicName = null,}) {
  return _then(_LessonModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,audioId: null == audioId ? _self.audioId : audioId // ignore: cast_nullable_to_non_nullable
as String,audioPath: null == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,segments: null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<SegmentModel>,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,audioSha256: null == audioSha256 ? _self.audioSha256 : audioSha256 // ignore: cast_nullable_to_non_nullable
as String,audioContentType: null == audioContentType ? _self.audioContentType : audioContentType // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,topicId: null == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String,topicName: null == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

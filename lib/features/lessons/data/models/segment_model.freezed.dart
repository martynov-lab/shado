// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'segment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SegmentModel {

 int get index; String get text;@JsonKey(name: 'start_ms') int get startMs;@JsonKey(name: 'end_ms') int get endMs;
/// Create a copy of SegmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SegmentModelCopyWith<SegmentModel> get copyWith => _$SegmentModelCopyWithImpl<SegmentModel>(this as SegmentModel, _$identity);

  /// Serializes this SegmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SegmentModel&&(identical(other.index, index) || other.index == index)&&(identical(other.text, text) || other.text == text)&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,text,startMs,endMs);

@override
String toString() {
  return 'SegmentModel(index: $index, text: $text, startMs: $startMs, endMs: $endMs)';
}


}

/// @nodoc
abstract mixin class $SegmentModelCopyWith<$Res>  {
  factory $SegmentModelCopyWith(SegmentModel value, $Res Function(SegmentModel) _then) = _$SegmentModelCopyWithImpl;
@useResult
$Res call({
 int index, String text,@JsonKey(name: 'start_ms') int startMs,@JsonKey(name: 'end_ms') int endMs
});




}
/// @nodoc
class _$SegmentModelCopyWithImpl<$Res>
    implements $SegmentModelCopyWith<$Res> {
  _$SegmentModelCopyWithImpl(this._self, this._then);

  final SegmentModel _self;
  final $Res Function(SegmentModel) _then;

/// Create a copy of SegmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? text = null,Object? startMs = null,Object? endMs = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SegmentModel].
extension SegmentModelPatterns on SegmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SegmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SegmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SegmentModel value)  $default,){
final _that = this;
switch (_that) {
case _SegmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SegmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _SegmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String text, @JsonKey(name: 'start_ms')  int startMs, @JsonKey(name: 'end_ms')  int endMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SegmentModel() when $default != null:
return $default(_that.index,_that.text,_that.startMs,_that.endMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String text, @JsonKey(name: 'start_ms')  int startMs, @JsonKey(name: 'end_ms')  int endMs)  $default,) {final _that = this;
switch (_that) {
case _SegmentModel():
return $default(_that.index,_that.text,_that.startMs,_that.endMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String text, @JsonKey(name: 'start_ms')  int startMs, @JsonKey(name: 'end_ms')  int endMs)?  $default,) {final _that = this;
switch (_that) {
case _SegmentModel() when $default != null:
return $default(_that.index,_that.text,_that.startMs,_that.endMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SegmentModel extends SegmentModel {
  const _SegmentModel({required this.index, required this.text, @JsonKey(name: 'start_ms') required this.startMs, @JsonKey(name: 'end_ms') required this.endMs}): super._();
  factory _SegmentModel.fromJson(Map<String, dynamic> json) => _$SegmentModelFromJson(json);

@override final  int index;
@override final  String text;
@override@JsonKey(name: 'start_ms') final  int startMs;
@override@JsonKey(name: 'end_ms') final  int endMs;

/// Create a copy of SegmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SegmentModelCopyWith<_SegmentModel> get copyWith => __$SegmentModelCopyWithImpl<_SegmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SegmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SegmentModel&&(identical(other.index, index) || other.index == index)&&(identical(other.text, text) || other.text == text)&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,text,startMs,endMs);

@override
String toString() {
  return 'SegmentModel(index: $index, text: $text, startMs: $startMs, endMs: $endMs)';
}


}

/// @nodoc
abstract mixin class _$SegmentModelCopyWith<$Res> implements $SegmentModelCopyWith<$Res> {
  factory _$SegmentModelCopyWith(_SegmentModel value, $Res Function(_SegmentModel) _then) = __$SegmentModelCopyWithImpl;
@override @useResult
$Res call({
 int index, String text,@JsonKey(name: 'start_ms') int startMs,@JsonKey(name: 'end_ms') int endMs
});




}
/// @nodoc
class __$SegmentModelCopyWithImpl<$Res>
    implements _$SegmentModelCopyWith<$Res> {
  __$SegmentModelCopyWithImpl(this._self, this._then);

  final _SegmentModel _self;
  final $Res Function(_SegmentModel) _then;

/// Create a copy of SegmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? text = null,Object? startMs = null,Object? endMs = null,}) {
  return _then(_SegmentModel(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

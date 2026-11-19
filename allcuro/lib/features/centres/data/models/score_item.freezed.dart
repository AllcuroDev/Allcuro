// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'score_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScoreItem {

 String get label; double get value;
/// Create a copy of ScoreItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoreItemCopyWith<ScoreItem> get copyWith => _$ScoreItemCopyWithImpl<ScoreItem>(this as ScoreItem, _$identity);

  /// Serializes this ScoreItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoreItem&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'ScoreItem(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $ScoreItemCopyWith<$Res>  {
  factory $ScoreItemCopyWith(ScoreItem value, $Res Function(ScoreItem) _then) = _$ScoreItemCopyWithImpl;
@useResult
$Res call({
 String label, double value
});




}
/// @nodoc
class _$ScoreItemCopyWithImpl<$Res>
    implements $ScoreItemCopyWith<$Res> {
  _$ScoreItemCopyWithImpl(this._self, this._then);

  final ScoreItem _self;
  final $Res Function(ScoreItem) _then;

/// Create a copy of ScoreItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,}) {
  return _then(ScoreItem(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ScoreItem].
extension ScoreItemPatterns on ScoreItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoreItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoreItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoreItem value)  $default,){
final _that = this;
switch (_that) {
case _ScoreItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoreItem value)?  $default,){
final _that = this;
switch (_that) {
case _ScoreItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  double value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoreItem() when $default != null:
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  double value)  $default,) {final _that = this;
switch (_that) {
case _ScoreItem():
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  double value)?  $default,) {final _that = this;
switch (_that) {
case _ScoreItem() when $default != null:
return $default(_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoreItem implements ScoreItem {
  const _ScoreItem({required this.label, required this.value});
  factory _ScoreItem.fromJson(Map<String, dynamic> json) => _$ScoreItemFromJson(json);

@override final  String label;
@override final  double value;

/// Create a copy of ScoreItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoreItemCopyWith<_ScoreItem> get copyWith => __$ScoreItemCopyWithImpl<_ScoreItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoreItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoreItem&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'ScoreItem(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ScoreItemCopyWith<$Res> implements $ScoreItemCopyWith<$Res> {
  factory _$ScoreItemCopyWith(_ScoreItem value, $Res Function(_ScoreItem) _then) = __$ScoreItemCopyWithImpl;
@override @useResult
$Res call({
 String label, double value
});




}
/// @nodoc
class __$ScoreItemCopyWithImpl<$Res>
    implements _$ScoreItemCopyWith<$Res> {
  __$ScoreItemCopyWithImpl(this._self, this._then);

  final _ScoreItem _self;
  final $Res Function(_ScoreItem) _then;

/// Create a copy of ScoreItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,}) {
  return _then(_ScoreItem(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

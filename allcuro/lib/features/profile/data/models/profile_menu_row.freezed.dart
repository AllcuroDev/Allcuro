// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_menu_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileMenuRow {

 String get iconKey; String get label; String get hint;
/// Create a copy of ProfileMenuRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileMenuRowCopyWith<ProfileMenuRow> get copyWith => _$ProfileMenuRowCopyWithImpl<ProfileMenuRow>(this as ProfileMenuRow, _$identity);

  /// Serializes this ProfileMenuRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileMenuRow&&(identical(other.iconKey, iconKey) || other.iconKey == iconKey)&&(identical(other.label, label) || other.label == label)&&(identical(other.hint, hint) || other.hint == hint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,iconKey,label,hint);

@override
String toString() {
  return 'ProfileMenuRow(iconKey: $iconKey, label: $label, hint: $hint)';
}


}

/// @nodoc
abstract mixin class $ProfileMenuRowCopyWith<$Res>  {
  factory $ProfileMenuRowCopyWith(ProfileMenuRow value, $Res Function(ProfileMenuRow) _then) = _$ProfileMenuRowCopyWithImpl;
@useResult
$Res call({
 String iconKey, String label, String hint
});




}
/// @nodoc
class _$ProfileMenuRowCopyWithImpl<$Res>
    implements $ProfileMenuRowCopyWith<$Res> {
  _$ProfileMenuRowCopyWithImpl(this._self, this._then);

  final ProfileMenuRow _self;
  final $Res Function(ProfileMenuRow) _then;

/// Create a copy of ProfileMenuRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? iconKey = null,Object? label = null,Object? hint = null,}) {
  return _then(ProfileMenuRow(
iconKey: null == iconKey ? _self.iconKey : iconKey // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hint: null == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileMenuRow].
extension ProfileMenuRowPatterns on ProfileMenuRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileMenuRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileMenuRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileMenuRow value)  $default,){
final _that = this;
switch (_that) {
case _ProfileMenuRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileMenuRow value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileMenuRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String iconKey,  String label,  String hint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileMenuRow() when $default != null:
return $default(_that.iconKey,_that.label,_that.hint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String iconKey,  String label,  String hint)  $default,) {final _that = this;
switch (_that) {
case _ProfileMenuRow():
return $default(_that.iconKey,_that.label,_that.hint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String iconKey,  String label,  String hint)?  $default,) {final _that = this;
switch (_that) {
case _ProfileMenuRow() when $default != null:
return $default(_that.iconKey,_that.label,_that.hint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileMenuRow implements ProfileMenuRow {
  const _ProfileMenuRow({required this.iconKey, required this.label, required this.hint});
  factory _ProfileMenuRow.fromJson(Map<String, dynamic> json) => _$ProfileMenuRowFromJson(json);

@override final  String iconKey;
@override final  String label;
@override final  String hint;

/// Create a copy of ProfileMenuRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileMenuRowCopyWith<_ProfileMenuRow> get copyWith => __$ProfileMenuRowCopyWithImpl<_ProfileMenuRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileMenuRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileMenuRow&&(identical(other.iconKey, iconKey) || other.iconKey == iconKey)&&(identical(other.label, label) || other.label == label)&&(identical(other.hint, hint) || other.hint == hint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,iconKey,label,hint);

@override
String toString() {
  return 'ProfileMenuRow(iconKey: $iconKey, label: $label, hint: $hint)';
}


}

/// @nodoc
abstract mixin class _$ProfileMenuRowCopyWith<$Res> implements $ProfileMenuRowCopyWith<$Res> {
  factory _$ProfileMenuRowCopyWith(_ProfileMenuRow value, $Res Function(_ProfileMenuRow) _then) = __$ProfileMenuRowCopyWithImpl;
@override @useResult
$Res call({
 String iconKey, String label, String hint
});




}
/// @nodoc
class __$ProfileMenuRowCopyWithImpl<$Res>
    implements _$ProfileMenuRowCopyWith<$Res> {
  __$ProfileMenuRowCopyWithImpl(this._self, this._then);

  final _ProfileMenuRow _self;
  final $Res Function(_ProfileMenuRow) _then;

/// Create a copy of ProfileMenuRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? iconKey = null,Object? label = null,Object? hint = null,}) {
  return _then(_ProfileMenuRow(
iconKey: null == iconKey ? _self.iconKey : iconKey // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hint: null == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

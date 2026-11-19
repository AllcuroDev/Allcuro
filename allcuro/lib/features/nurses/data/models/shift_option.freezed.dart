// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftOption {

 String get label; int get price; bool get available;/// 'per visit', 'per shift', 'per day'… (partner_offerings.unit).
 String get unit;/// Price before the admin's discount; 0 when there is none.
 int get mrp; String? get serviceId;
/// Create a copy of ShiftOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftOptionCopyWith<ShiftOption> get copyWith => _$ShiftOptionCopyWithImpl<ShiftOption>(this as ShiftOption, _$identity);

  /// Serializes this ShiftOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftOption&&(identical(other.label, label) || other.label == label)&&(identical(other.price, price) || other.price == price)&&(identical(other.available, available) || other.available == available)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,price,available,unit,mrp,serviceId);

@override
String toString() {
  return 'ShiftOption(label: $label, price: $price, available: $available, unit: $unit, mrp: $mrp, serviceId: $serviceId)';
}


}

/// @nodoc
abstract mixin class $ShiftOptionCopyWith<$Res>  {
  factory $ShiftOptionCopyWith(ShiftOption value, $Res Function(ShiftOption) _then) = _$ShiftOptionCopyWithImpl;
@useResult
$Res call({
 String label, int price, bool available, String unit, int mrp, String? serviceId
});




}
/// @nodoc
class _$ShiftOptionCopyWithImpl<$Res>
    implements $ShiftOptionCopyWith<$Res> {
  _$ShiftOptionCopyWithImpl(this._self, this._then);

  final ShiftOption _self;
  final $Res Function(ShiftOption) _then;

/// Create a copy of ShiftOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? price = null,Object? available = null,Object? unit = null,Object? mrp = null,Object? serviceId = freezed,}) {
  return _then(ShiftOption(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as int,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftOption].
extension ShiftOptionPatterns on ShiftOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftOption value)  $default,){
final _that = this;
switch (_that) {
case _ShiftOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftOption value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  int price,  bool available,  String unit,  int mrp,  String? serviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftOption() when $default != null:
return $default(_that.label,_that.price,_that.available,_that.unit,_that.mrp,_that.serviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  int price,  bool available,  String unit,  int mrp,  String? serviceId)  $default,) {final _that = this;
switch (_that) {
case _ShiftOption():
return $default(_that.label,_that.price,_that.available,_that.unit,_that.mrp,_that.serviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  int price,  bool available,  String unit,  int mrp,  String? serviceId)?  $default,) {final _that = this;
switch (_that) {
case _ShiftOption() when $default != null:
return $default(_that.label,_that.price,_that.available,_that.unit,_that.mrp,_that.serviceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftOption implements ShiftOption {
  const _ShiftOption({required this.label, required this.price, required this.available, this.unit = '', this.mrp = 0, this.serviceId});
  factory _ShiftOption.fromJson(Map<String, dynamic> json) => _$ShiftOptionFromJson(json);

@override final  String label;
@override final  int price;
@override final  bool available;
/// 'per visit', 'per shift', 'per day'… (partner_offerings.unit).
@override@JsonKey() final  String unit;
/// Price before the admin's discount; 0 when there is none.
@override@JsonKey() final  int mrp;
@override final  String? serviceId;

/// Create a copy of ShiftOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftOptionCopyWith<_ShiftOption> get copyWith => __$ShiftOptionCopyWithImpl<_ShiftOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftOption&&(identical(other.label, label) || other.label == label)&&(identical(other.price, price) || other.price == price)&&(identical(other.available, available) || other.available == available)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,price,available,unit,mrp,serviceId);

@override
String toString() {
  return 'ShiftOption(label: $label, price: $price, available: $available, unit: $unit, mrp: $mrp, serviceId: $serviceId)';
}


}

/// @nodoc
abstract mixin class _$ShiftOptionCopyWith<$Res> implements $ShiftOptionCopyWith<$Res> {
  factory _$ShiftOptionCopyWith(_ShiftOption value, $Res Function(_ShiftOption) _then) = __$ShiftOptionCopyWithImpl;
@override @useResult
$Res call({
 String label, int price, bool available, String unit, int mrp, String? serviceId
});




}
/// @nodoc
class __$ShiftOptionCopyWithImpl<$Res>
    implements _$ShiftOptionCopyWith<$Res> {
  __$ShiftOptionCopyWithImpl(this._self, this._then);

  final _ShiftOption _self;
  final $Res Function(_ShiftOption) _then;

/// Create a copy of ShiftOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? price = null,Object? available = null,Object? unit = null,Object? mrp = null,Object? serviceId = freezed,}) {
  return _then(_ShiftOption(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as int,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

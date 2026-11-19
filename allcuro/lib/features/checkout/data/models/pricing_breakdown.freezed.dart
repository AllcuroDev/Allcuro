// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pricing_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PricingBreakdown {

 int get base; int get discount; int get fee; int get gst; int get total;
/// Create a copy of PricingBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PricingBreakdownCopyWith<PricingBreakdown> get copyWith => _$PricingBreakdownCopyWithImpl<PricingBreakdown>(this as PricingBreakdown, _$identity);

  /// Serializes this PricingBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PricingBreakdown&&(identical(other.base, base) || other.base == base)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.gst, gst) || other.gst == gst)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,base,discount,fee,gst,total);

@override
String toString() {
  return 'PricingBreakdown(base: $base, discount: $discount, fee: $fee, gst: $gst, total: $total)';
}


}

/// @nodoc
abstract mixin class $PricingBreakdownCopyWith<$Res>  {
  factory $PricingBreakdownCopyWith(PricingBreakdown value, $Res Function(PricingBreakdown) _then) = _$PricingBreakdownCopyWithImpl;
@useResult
$Res call({
 int base, int discount, int fee, int gst, int total
});




}
/// @nodoc
class _$PricingBreakdownCopyWithImpl<$Res>
    implements $PricingBreakdownCopyWith<$Res> {
  _$PricingBreakdownCopyWithImpl(this._self, this._then);

  final PricingBreakdown _self;
  final $Res Function(PricingBreakdown) _then;

/// Create a copy of PricingBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? base = null,Object? discount = null,Object? fee = null,Object? gst = null,Object? total = null,}) {
  return _then(PricingBreakdown(
base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int,gst: null == gst ? _self.gst : gst // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PricingBreakdown].
extension PricingBreakdownPatterns on PricingBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PricingBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PricingBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PricingBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _PricingBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PricingBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _PricingBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int base,  int discount,  int fee,  int gst,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PricingBreakdown() when $default != null:
return $default(_that.base,_that.discount,_that.fee,_that.gst,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int base,  int discount,  int fee,  int gst,  int total)  $default,) {final _that = this;
switch (_that) {
case _PricingBreakdown():
return $default(_that.base,_that.discount,_that.fee,_that.gst,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int base,  int discount,  int fee,  int gst,  int total)?  $default,) {final _that = this;
switch (_that) {
case _PricingBreakdown() when $default != null:
return $default(_that.base,_that.discount,_that.fee,_that.gst,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PricingBreakdown implements PricingBreakdown {
  const _PricingBreakdown({required this.base, required this.discount, required this.fee, required this.gst, required this.total});
  factory _PricingBreakdown.fromJson(Map<String, dynamic> json) => _$PricingBreakdownFromJson(json);

@override final  int base;
@override final  int discount;
@override final  int fee;
@override final  int gst;
@override final  int total;

/// Create a copy of PricingBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PricingBreakdownCopyWith<_PricingBreakdown> get copyWith => __$PricingBreakdownCopyWithImpl<_PricingBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PricingBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PricingBreakdown&&(identical(other.base, base) || other.base == base)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.gst, gst) || other.gst == gst)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,base,discount,fee,gst,total);

@override
String toString() {
  return 'PricingBreakdown(base: $base, discount: $discount, fee: $fee, gst: $gst, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PricingBreakdownCopyWith<$Res> implements $PricingBreakdownCopyWith<$Res> {
  factory _$PricingBreakdownCopyWith(_PricingBreakdown value, $Res Function(_PricingBreakdown) _then) = __$PricingBreakdownCopyWithImpl;
@override @useResult
$Res call({
 int base, int discount, int fee, int gst, int total
});




}
/// @nodoc
class __$PricingBreakdownCopyWithImpl<$Res>
    implements _$PricingBreakdownCopyWith<$Res> {
  __$PricingBreakdownCopyWithImpl(this._self, this._then);

  final _PricingBreakdown _self;
  final $Res Function(_PricingBreakdown) _then;

/// Create a copy of PricingBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? base = null,Object? discount = null,Object? fee = null,Object? gst = null,Object? total = null,}) {
  return _then(_PricingBreakdown(
base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int,gst: null == gst ? _self.gst : gst // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'equipment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Equipment {

 String get id; String get name; String get category; String get photo; int get perDay; int get perMonth; int get deposit; String get condition; String get availableIn; String get description; List<String> get features; bool get inStock;
/// Create a copy of Equipment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EquipmentCopyWith<Equipment> get copyWith => _$EquipmentCopyWithImpl<Equipment>(this as Equipment, _$identity);

  /// Serializes this Equipment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Equipment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.perDay, perDay) || other.perDay == perDay)&&(identical(other.perMonth, perMonth) || other.perMonth == perMonth)&&(identical(other.deposit, deposit) || other.deposit == deposit)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.availableIn, availableIn) || other.availableIn == availableIn)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.inStock, inStock) || other.inStock == inStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,photo,perDay,perMonth,deposit,condition,availableIn,description,const DeepCollectionEquality().hash(features),inStock);

@override
String toString() {
  return 'Equipment(id: $id, name: $name, category: $category, photo: $photo, perDay: $perDay, perMonth: $perMonth, deposit: $deposit, condition: $condition, availableIn: $availableIn, description: $description, features: $features, inStock: $inStock)';
}


}

/// @nodoc
abstract mixin class $EquipmentCopyWith<$Res>  {
  factory $EquipmentCopyWith(Equipment value, $Res Function(Equipment) _then) = _$EquipmentCopyWithImpl;
@useResult
$Res call({
 String id, String name, String category, String photo, int perDay, int perMonth, int deposit, String condition, String availableIn, String description, List<String> features, bool inStock
});




}
/// @nodoc
class _$EquipmentCopyWithImpl<$Res>
    implements $EquipmentCopyWith<$Res> {
  _$EquipmentCopyWithImpl(this._self, this._then);

  final Equipment _self;
  final $Res Function(Equipment) _then;

/// Create a copy of Equipment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? photo = null,Object? perDay = null,Object? perMonth = null,Object? deposit = null,Object? condition = null,Object? availableIn = null,Object? description = null,Object? features = null,Object? inStock = null,}) {
  return _then(Equipment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,perDay: null == perDay ? _self.perDay : perDay // ignore: cast_nullable_to_non_nullable
as int,perMonth: null == perMonth ? _self.perMonth : perMonth // ignore: cast_nullable_to_non_nullable
as int,deposit: null == deposit ? _self.deposit : deposit // ignore: cast_nullable_to_non_nullable
as int,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,availableIn: null == availableIn ? _self.availableIn : availableIn // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Equipment].
extension EquipmentPatterns on Equipment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Equipment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Equipment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Equipment value)  $default,){
final _that = this;
switch (_that) {
case _Equipment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Equipment value)?  $default,){
final _that = this;
switch (_that) {
case _Equipment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String category,  String photo,  int perDay,  int perMonth,  int deposit,  String condition,  String availableIn,  String description,  List<String> features,  bool inStock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Equipment() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.photo,_that.perDay,_that.perMonth,_that.deposit,_that.condition,_that.availableIn,_that.description,_that.features,_that.inStock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String category,  String photo,  int perDay,  int perMonth,  int deposit,  String condition,  String availableIn,  String description,  List<String> features,  bool inStock)  $default,) {final _that = this;
switch (_that) {
case _Equipment():
return $default(_that.id,_that.name,_that.category,_that.photo,_that.perDay,_that.perMonth,_that.deposit,_that.condition,_that.availableIn,_that.description,_that.features,_that.inStock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String category,  String photo,  int perDay,  int perMonth,  int deposit,  String condition,  String availableIn,  String description,  List<String> features,  bool inStock)?  $default,) {final _that = this;
switch (_that) {
case _Equipment() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.photo,_that.perDay,_that.perMonth,_that.deposit,_that.condition,_that.availableIn,_that.description,_that.features,_that.inStock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Equipment implements Equipment {
  const _Equipment({required this.id, required this.name, required this.category, required this.photo, required this.perDay, required this.perMonth, required this.deposit, required this.condition, required this.availableIn, this.description = '',  List<String> features = const <String>[], this.inStock = true}): _features = features;
  factory _Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);

@override final  String id;
@override final  String name;
@override final  String category;
@override final  String photo;
@override final  int perDay;
@override final  int perMonth;
@override final  int deposit;
@override final  String condition;
@override final  String availableIn;
@override@JsonKey() final  String description;
 final  List<String> _features;
@override@JsonKey() List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

@override@JsonKey() final  bool inStock;

/// Create a copy of Equipment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EquipmentCopyWith<_Equipment> get copyWith => __$EquipmentCopyWithImpl<_Equipment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EquipmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Equipment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.perDay, perDay) || other.perDay == perDay)&&(identical(other.perMonth, perMonth) || other.perMonth == perMonth)&&(identical(other.deposit, deposit) || other.deposit == deposit)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.availableIn, availableIn) || other.availableIn == availableIn)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.inStock, inStock) || other.inStock == inStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,photo,perDay,perMonth,deposit,condition,availableIn,description,const DeepCollectionEquality().hash(_features),inStock);

@override
String toString() {
  return 'Equipment(id: $id, name: $name, category: $category, photo: $photo, perDay: $perDay, perMonth: $perMonth, deposit: $deposit, condition: $condition, availableIn: $availableIn, description: $description, features: $features, inStock: $inStock)';
}


}

/// @nodoc
abstract mixin class _$EquipmentCopyWith<$Res> implements $EquipmentCopyWith<$Res> {
  factory _$EquipmentCopyWith(_Equipment value, $Res Function(_Equipment) _then) = __$EquipmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String category, String photo, int perDay, int perMonth, int deposit, String condition, String availableIn, String description, List<String> features, bool inStock
});




}
/// @nodoc
class __$EquipmentCopyWithImpl<$Res>
    implements _$EquipmentCopyWith<$Res> {
  __$EquipmentCopyWithImpl(this._self, this._then);

  final _Equipment _self;
  final $Res Function(_Equipment) _then;

/// Create a copy of Equipment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? photo = null,Object? perDay = null,Object? perMonth = null,Object? deposit = null,Object? condition = null,Object? availableIn = null,Object? description = null,Object? features = null,Object? inStock = null,}) {
  return _then(_Equipment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,perDay: null == perDay ? _self.perDay : perDay // ignore: cast_nullable_to_non_nullable
as int,perMonth: null == perMonth ? _self.perMonth : perMonth // ignore: cast_nullable_to_non_nullable
as int,deposit: null == deposit ? _self.deposit : deposit // ignore: cast_nullable_to_non_nullable
as int,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,availableIn: null == availableIn ? _self.availableIn : availableIn // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

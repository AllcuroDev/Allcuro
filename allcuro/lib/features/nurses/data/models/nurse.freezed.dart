// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nurse.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Nurse {

 String get id; String get name;/// Photo URL from Supabase storage; '' when the partner has none.
 String get photo; String get allcuroId; String get level; int get experience; String get city; List<String> get languages; List<String> get tags; double get rating; int get reviews; List<String> get highlights; List<ShiftOption> get shifts; Employment get employment;/// nurse | doctor | physiotherapist | caregiver (partners.kind).
 String get kind;/// partners.id — the uuid behind the URL slug in [id].
 String get partnerId; String get bio; bool get available;
/// Create a copy of Nurse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NurseCopyWith<Nurse> get copyWith => _$NurseCopyWithImpl<Nurse>(this as Nurse, _$identity);

  /// Serializes this Nurse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nurse&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.allcuroId, allcuroId) || other.allcuroId == allcuroId)&&(identical(other.level, level) || other.level == level)&&(identical(other.experience, experience) || other.experience == experience)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other.languages, languages)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&const DeepCollectionEquality().equals(other.highlights, highlights)&&const DeepCollectionEquality().equals(other.shifts, shifts)&&(identical(other.employment, employment) || other.employment == employment)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,photo,allcuroId,level,experience,city,const DeepCollectionEquality().hash(languages),const DeepCollectionEquality().hash(tags),rating,reviews,const DeepCollectionEquality().hash(highlights),const DeepCollectionEquality().hash(shifts),employment,kind,partnerId,bio,available);

@override
String toString() {
  return 'Nurse(id: $id, name: $name, photo: $photo, allcuroId: $allcuroId, level: $level, experience: $experience, city: $city, languages: $languages, tags: $tags, rating: $rating, reviews: $reviews, highlights: $highlights, shifts: $shifts, employment: $employment, kind: $kind, partnerId: $partnerId, bio: $bio, available: $available)';
}


}

/// @nodoc
abstract mixin class $NurseCopyWith<$Res>  {
  factory $NurseCopyWith(Nurse value, $Res Function(Nurse) _then) = _$NurseCopyWithImpl;
@useResult
$Res call({
 String id, String name, String photo, String allcuroId, String level, int experience, String city, List<String> languages, List<String> tags, double rating, int reviews, List<String> highlights, List<ShiftOption> shifts, Employment employment, String kind, String partnerId, String bio, bool available
});




}
/// @nodoc
class _$NurseCopyWithImpl<$Res>
    implements $NurseCopyWith<$Res> {
  _$NurseCopyWithImpl(this._self, this._then);

  final Nurse _self;
  final $Res Function(Nurse) _then;

/// Create a copy of Nurse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? photo = null,Object? allcuroId = null,Object? level = null,Object? experience = null,Object? city = null,Object? languages = null,Object? tags = null,Object? rating = null,Object? reviews = null,Object? highlights = null,Object? shifts = null,Object? employment = null,Object? kind = null,Object? partnerId = null,Object? bio = null,Object? available = null,}) {
  return _then(Nurse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,allcuroId: null == allcuroId ? _self.allcuroId : allcuroId // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,experience: null == experience ? _self.experience : experience // ignore: cast_nullable_to_non_nullable
as int,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,shifts: null == shifts ? _self.shifts : shifts // ignore: cast_nullable_to_non_nullable
as List<ShiftOption>,employment: null == employment ? _self.employment : employment // ignore: cast_nullable_to_non_nullable
as Employment,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Nurse].
extension NursePatterns on Nurse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Nurse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Nurse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Nurse value)  $default,){
final _that = this;
switch (_that) {
case _Nurse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Nurse value)?  $default,){
final _that = this;
switch (_that) {
case _Nurse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String photo,  String allcuroId,  String level,  int experience,  String city,  List<String> languages,  List<String> tags,  double rating,  int reviews,  List<String> highlights,  List<ShiftOption> shifts,  Employment employment,  String kind,  String partnerId,  String bio,  bool available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Nurse() when $default != null:
return $default(_that.id,_that.name,_that.photo,_that.allcuroId,_that.level,_that.experience,_that.city,_that.languages,_that.tags,_that.rating,_that.reviews,_that.highlights,_that.shifts,_that.employment,_that.kind,_that.partnerId,_that.bio,_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String photo,  String allcuroId,  String level,  int experience,  String city,  List<String> languages,  List<String> tags,  double rating,  int reviews,  List<String> highlights,  List<ShiftOption> shifts,  Employment employment,  String kind,  String partnerId,  String bio,  bool available)  $default,) {final _that = this;
switch (_that) {
case _Nurse():
return $default(_that.id,_that.name,_that.photo,_that.allcuroId,_that.level,_that.experience,_that.city,_that.languages,_that.tags,_that.rating,_that.reviews,_that.highlights,_that.shifts,_that.employment,_that.kind,_that.partnerId,_that.bio,_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String photo,  String allcuroId,  String level,  int experience,  String city,  List<String> languages,  List<String> tags,  double rating,  int reviews,  List<String> highlights,  List<ShiftOption> shifts,  Employment employment,  String kind,  String partnerId,  String bio,  bool available)?  $default,) {final _that = this;
switch (_that) {
case _Nurse() when $default != null:
return $default(_that.id,_that.name,_that.photo,_that.allcuroId,_that.level,_that.experience,_that.city,_that.languages,_that.tags,_that.rating,_that.reviews,_that.highlights,_that.shifts,_that.employment,_that.kind,_that.partnerId,_that.bio,_that.available);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Nurse implements Nurse {
  const _Nurse({required this.id, required this.name, required this.photo, required this.allcuroId, required this.level, required this.experience, required this.city, required  List<String> languages, required  List<String> tags, required this.rating, required this.reviews, required  List<String> highlights, required  List<ShiftOption> shifts, required this.employment, this.kind = 'nurse', this.partnerId = '', this.bio = '', this.available = true}): _languages = languages,_tags = tags,_highlights = highlights,_shifts = shifts;
  factory _Nurse.fromJson(Map<String, dynamic> json) => _$NurseFromJson(json);

@override final  String id;
@override final  String name;
/// Photo URL from Supabase storage; '' when the partner has none.
@override final  String photo;
@override final  String allcuroId;
@override final  String level;
@override final  int experience;
@override final  String city;
 final  List<String> _languages;
@override List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  double rating;
@override final  int reviews;
 final  List<String> _highlights;
@override List<String> get highlights {
  if (_highlights is EqualUnmodifiableListView) return _highlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_highlights);
}

 final  List<ShiftOption> _shifts;
@override List<ShiftOption> get shifts {
  if (_shifts is EqualUnmodifiableListView) return _shifts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shifts);
}

@override final  Employment employment;
/// nurse | doctor | physiotherapist | caregiver (partners.kind).
@override@JsonKey() final  String kind;
/// partners.id — the uuid behind the URL slug in [id].
@override@JsonKey() final  String partnerId;
@override@JsonKey() final  String bio;
@override@JsonKey() final  bool available;

/// Create a copy of Nurse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NurseCopyWith<_Nurse> get copyWith => __$NurseCopyWithImpl<_Nurse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NurseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Nurse&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.allcuroId, allcuroId) || other.allcuroId == allcuroId)&&(identical(other.level, level) || other.level == level)&&(identical(other.experience, experience) || other.experience == experience)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other._languages, _languages)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&const DeepCollectionEquality().equals(other._highlights, _highlights)&&const DeepCollectionEquality().equals(other._shifts, _shifts)&&(identical(other.employment, employment) || other.employment == employment)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,photo,allcuroId,level,experience,city,const DeepCollectionEquality().hash(_languages),const DeepCollectionEquality().hash(_tags),rating,reviews,const DeepCollectionEquality().hash(_highlights),const DeepCollectionEquality().hash(_shifts),employment,kind,partnerId,bio,available);

@override
String toString() {
  return 'Nurse(id: $id, name: $name, photo: $photo, allcuroId: $allcuroId, level: $level, experience: $experience, city: $city, languages: $languages, tags: $tags, rating: $rating, reviews: $reviews, highlights: $highlights, shifts: $shifts, employment: $employment, kind: $kind, partnerId: $partnerId, bio: $bio, available: $available)';
}


}

/// @nodoc
abstract mixin class _$NurseCopyWith<$Res> implements $NurseCopyWith<$Res> {
  factory _$NurseCopyWith(_Nurse value, $Res Function(_Nurse) _then) = __$NurseCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String photo, String allcuroId, String level, int experience, String city, List<String> languages, List<String> tags, double rating, int reviews, List<String> highlights, List<ShiftOption> shifts, Employment employment, String kind, String partnerId, String bio, bool available
});




}
/// @nodoc
class __$NurseCopyWithImpl<$Res>
    implements _$NurseCopyWith<$Res> {
  __$NurseCopyWithImpl(this._self, this._then);

  final _Nurse _self;
  final $Res Function(_Nurse) _then;

/// Create a copy of Nurse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? photo = null,Object? allcuroId = null,Object? level = null,Object? experience = null,Object? city = null,Object? languages = null,Object? tags = null,Object? rating = null,Object? reviews = null,Object? highlights = null,Object? shifts = null,Object? employment = null,Object? kind = null,Object? partnerId = null,Object? bio = null,Object? available = null,}) {
  return _then(_Nurse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,allcuroId: null == allcuroId ? _self.allcuroId : allcuroId // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,experience: null == experience ? _self.experience : experience // ignore: cast_nullable_to_non_nullable
as int,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,highlights: null == highlights ? _self._highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,shifts: null == shifts ? _self._shifts : shifts // ignore: cast_nullable_to_non_nullable
as List<ShiftOption>,employment: null == employment ? _self.employment : employment // ignore: cast_nullable_to_non_nullable
as Employment,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

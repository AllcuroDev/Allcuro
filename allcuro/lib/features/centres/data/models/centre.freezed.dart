// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'centre.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Centre {

 String get id; String get name; String get type; String get locality; String get city; String get photo; int get photoCount; double get rating; int get reviews; int get since; String get licence; String get staffRatio; int get pricePerDay; int get pricePerMonth; int get bedsLeft; List<String> get services; List<ScoreItem> get scores; String get partnerId; String get phone; String get about; List<String> get roomTypes; List<String> get photos;
/// Create a copy of Centre
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CentreCopyWith<Centre> get copyWith => _$CentreCopyWithImpl<Centre>(this as Centre, _$identity);

  /// Serializes this Centre to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Centre&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.city, city) || other.city == city)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.photoCount, photoCount) || other.photoCount == photoCount)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.since, since) || other.since == since)&&(identical(other.licence, licence) || other.licence == licence)&&(identical(other.staffRatio, staffRatio) || other.staffRatio == staffRatio)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.pricePerMonth, pricePerMonth) || other.pricePerMonth == pricePerMonth)&&(identical(other.bedsLeft, bedsLeft) || other.bedsLeft == bedsLeft)&&const DeepCollectionEquality().equals(other.services, services)&&const DeepCollectionEquality().equals(other.scores, scores)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.about, about) || other.about == about)&&const DeepCollectionEquality().equals(other.roomTypes, roomTypes)&&const DeepCollectionEquality().equals(other.photos, photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,type,locality,city,photo,photoCount,rating,reviews,since,licence,staffRatio,pricePerDay,pricePerMonth,bedsLeft,const DeepCollectionEquality().hash(services),const DeepCollectionEquality().hash(scores),partnerId,phone,about,const DeepCollectionEquality().hash(roomTypes),const DeepCollectionEquality().hash(photos)]);

@override
String toString() {
  return 'Centre(id: $id, name: $name, type: $type, locality: $locality, city: $city, photo: $photo, photoCount: $photoCount, rating: $rating, reviews: $reviews, since: $since, licence: $licence, staffRatio: $staffRatio, pricePerDay: $pricePerDay, pricePerMonth: $pricePerMonth, bedsLeft: $bedsLeft, services: $services, scores: $scores, partnerId: $partnerId, phone: $phone, about: $about, roomTypes: $roomTypes, photos: $photos)';
}


}

/// @nodoc
abstract mixin class $CentreCopyWith<$Res>  {
  factory $CentreCopyWith(Centre value, $Res Function(Centre) _then) = _$CentreCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, String locality, String city, String photo, int photoCount, double rating, int reviews, int since, String licence, String staffRatio, int pricePerDay, int pricePerMonth, int bedsLeft, List<String> services, List<ScoreItem> scores, String partnerId, String phone, String about, List<String> roomTypes, List<String> photos
});




}
/// @nodoc
class _$CentreCopyWithImpl<$Res>
    implements $CentreCopyWith<$Res> {
  _$CentreCopyWithImpl(this._self, this._then);

  final Centre _self;
  final $Res Function(Centre) _then;

/// Create a copy of Centre
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? locality = null,Object? city = null,Object? photo = null,Object? photoCount = null,Object? rating = null,Object? reviews = null,Object? since = null,Object? licence = null,Object? staffRatio = null,Object? pricePerDay = null,Object? pricePerMonth = null,Object? bedsLeft = null,Object? services = null,Object? scores = null,Object? partnerId = null,Object? phone = null,Object? about = null,Object? roomTypes = null,Object? photos = null,}) {
  return _then(Centre(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,locality: null == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,photoCount: null == photoCount ? _self.photoCount : photoCount // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,licence: null == licence ? _self.licence : licence // ignore: cast_nullable_to_non_nullable
as String,staffRatio: null == staffRatio ? _self.staffRatio : staffRatio // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as int,pricePerMonth: null == pricePerMonth ? _self.pricePerMonth : pricePerMonth // ignore: cast_nullable_to_non_nullable
as int,bedsLeft: null == bedsLeft ? _self.bedsLeft : bedsLeft // ignore: cast_nullable_to_non_nullable
as int,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<String>,scores: null == scores ? _self.scores : scores // ignore: cast_nullable_to_non_nullable
as List<ScoreItem>,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String,roomTypes: null == roomTypes ? _self.roomTypes : roomTypes // ignore: cast_nullable_to_non_nullable
as List<String>,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Centre].
extension CentrePatterns on Centre {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Centre value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Centre() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Centre value)  $default,){
final _that = this;
switch (_that) {
case _Centre():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Centre value)?  $default,){
final _that = this;
switch (_that) {
case _Centre() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String locality,  String city,  String photo,  int photoCount,  double rating,  int reviews,  int since,  String licence,  String staffRatio,  int pricePerDay,  int pricePerMonth,  int bedsLeft,  List<String> services,  List<ScoreItem> scores,  String partnerId,  String phone,  String about,  List<String> roomTypes,  List<String> photos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Centre() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.locality,_that.city,_that.photo,_that.photoCount,_that.rating,_that.reviews,_that.since,_that.licence,_that.staffRatio,_that.pricePerDay,_that.pricePerMonth,_that.bedsLeft,_that.services,_that.scores,_that.partnerId,_that.phone,_that.about,_that.roomTypes,_that.photos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String locality,  String city,  String photo,  int photoCount,  double rating,  int reviews,  int since,  String licence,  String staffRatio,  int pricePerDay,  int pricePerMonth,  int bedsLeft,  List<String> services,  List<ScoreItem> scores,  String partnerId,  String phone,  String about,  List<String> roomTypes,  List<String> photos)  $default,) {final _that = this;
switch (_that) {
case _Centre():
return $default(_that.id,_that.name,_that.type,_that.locality,_that.city,_that.photo,_that.photoCount,_that.rating,_that.reviews,_that.since,_that.licence,_that.staffRatio,_that.pricePerDay,_that.pricePerMonth,_that.bedsLeft,_that.services,_that.scores,_that.partnerId,_that.phone,_that.about,_that.roomTypes,_that.photos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  String locality,  String city,  String photo,  int photoCount,  double rating,  int reviews,  int since,  String licence,  String staffRatio,  int pricePerDay,  int pricePerMonth,  int bedsLeft,  List<String> services,  List<ScoreItem> scores,  String partnerId,  String phone,  String about,  List<String> roomTypes,  List<String> photos)?  $default,) {final _that = this;
switch (_that) {
case _Centre() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.locality,_that.city,_that.photo,_that.photoCount,_that.rating,_that.reviews,_that.since,_that.licence,_that.staffRatio,_that.pricePerDay,_that.pricePerMonth,_that.bedsLeft,_that.services,_that.scores,_that.partnerId,_that.phone,_that.about,_that.roomTypes,_that.photos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Centre implements Centre {
  const _Centre({required this.id, required this.name, required this.type, required this.locality, required this.city, required this.photo, required this.photoCount, required this.rating, required this.reviews, required this.since, required this.licence, required this.staffRatio, required this.pricePerDay, required this.pricePerMonth, required this.bedsLeft, required  List<String> services, required  List<ScoreItem> scores, this.partnerId = '', this.phone = '', this.about = '',  List<String> roomTypes = const <String>[],  List<String> photos = const <String>[]}): _services = services,_scores = scores,_roomTypes = roomTypes,_photos = photos;
  factory _Centre.fromJson(Map<String, dynamic> json) => _$CentreFromJson(json);

@override final  String id;
@override final  String name;
@override final  String type;
@override final  String locality;
@override final  String city;
@override final  String photo;
@override final  int photoCount;
@override final  double rating;
@override final  int reviews;
@override final  int since;
@override final  String licence;
@override final  String staffRatio;
@override final  int pricePerDay;
@override final  int pricePerMonth;
@override final  int bedsLeft;
 final  List<String> _services;
@override List<String> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}

 final  List<ScoreItem> _scores;
@override List<ScoreItem> get scores {
  if (_scores is EqualUnmodifiableListView) return _scores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scores);
}

@override@JsonKey() final  String partnerId;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String about;
 final  List<String> _roomTypes;
@override@JsonKey() List<String> get roomTypes {
  if (_roomTypes is EqualUnmodifiableListView) return _roomTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roomTypes);
}

 final  List<String> _photos;
@override@JsonKey() List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}


/// Create a copy of Centre
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CentreCopyWith<_Centre> get copyWith => __$CentreCopyWithImpl<_Centre>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CentreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Centre&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.city, city) || other.city == city)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.photoCount, photoCount) || other.photoCount == photoCount)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.since, since) || other.since == since)&&(identical(other.licence, licence) || other.licence == licence)&&(identical(other.staffRatio, staffRatio) || other.staffRatio == staffRatio)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.pricePerMonth, pricePerMonth) || other.pricePerMonth == pricePerMonth)&&(identical(other.bedsLeft, bedsLeft) || other.bedsLeft == bedsLeft)&&const DeepCollectionEquality().equals(other._services, _services)&&const DeepCollectionEquality().equals(other._scores, _scores)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.about, about) || other.about == about)&&const DeepCollectionEquality().equals(other._roomTypes, _roomTypes)&&const DeepCollectionEquality().equals(other._photos, _photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,type,locality,city,photo,photoCount,rating,reviews,since,licence,staffRatio,pricePerDay,pricePerMonth,bedsLeft,const DeepCollectionEquality().hash(_services),const DeepCollectionEquality().hash(_scores),partnerId,phone,about,const DeepCollectionEquality().hash(_roomTypes),const DeepCollectionEquality().hash(_photos)]);

@override
String toString() {
  return 'Centre(id: $id, name: $name, type: $type, locality: $locality, city: $city, photo: $photo, photoCount: $photoCount, rating: $rating, reviews: $reviews, since: $since, licence: $licence, staffRatio: $staffRatio, pricePerDay: $pricePerDay, pricePerMonth: $pricePerMonth, bedsLeft: $bedsLeft, services: $services, scores: $scores, partnerId: $partnerId, phone: $phone, about: $about, roomTypes: $roomTypes, photos: $photos)';
}


}

/// @nodoc
abstract mixin class _$CentreCopyWith<$Res> implements $CentreCopyWith<$Res> {
  factory _$CentreCopyWith(_Centre value, $Res Function(_Centre) _then) = __$CentreCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, String locality, String city, String photo, int photoCount, double rating, int reviews, int since, String licence, String staffRatio, int pricePerDay, int pricePerMonth, int bedsLeft, List<String> services, List<ScoreItem> scores, String partnerId, String phone, String about, List<String> roomTypes, List<String> photos
});




}
/// @nodoc
class __$CentreCopyWithImpl<$Res>
    implements _$CentreCopyWith<$Res> {
  __$CentreCopyWithImpl(this._self, this._then);

  final _Centre _self;
  final $Res Function(_Centre) _then;

/// Create a copy of Centre
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? locality = null,Object? city = null,Object? photo = null,Object? photoCount = null,Object? rating = null,Object? reviews = null,Object? since = null,Object? licence = null,Object? staffRatio = null,Object? pricePerDay = null,Object? pricePerMonth = null,Object? bedsLeft = null,Object? services = null,Object? scores = null,Object? partnerId = null,Object? phone = null,Object? about = null,Object? roomTypes = null,Object? photos = null,}) {
  return _then(_Centre(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,locality: null == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,photoCount: null == photoCount ? _self.photoCount : photoCount // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,licence: null == licence ? _self.licence : licence // ignore: cast_nullable_to_non_nullable
as String,staffRatio: null == staffRatio ? _self.staffRatio : staffRatio // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as int,pricePerMonth: null == pricePerMonth ? _self.pricePerMonth : pricePerMonth // ignore: cast_nullable_to_non_nullable
as int,bedsLeft: null == bedsLeft ? _self.bedsLeft : bedsLeft // ignore: cast_nullable_to_non_nullable
as int,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<String>,scores: null == scores ? _self._scores : scores // ignore: cast_nullable_to_non_nullable
as List<ScoreItem>,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String,roomTypes: null == roomTypes ? _self._roomTypes : roomTypes // ignore: cast_nullable_to_non_nullable
as List<String>,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'centre.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Centre _$CentreFromJson(Map<String, dynamic> json) => _Centre(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  locality: json['locality'] as String,
  city: json['city'] as String,
  photo: json['photo'] as String,
  photoCount: (json['photoCount'] as num).toInt(),
  rating: (json['rating'] as num).toDouble(),
  reviews: (json['reviews'] as num).toInt(),
  since: (json['since'] as num).toInt(),
  licence: json['licence'] as String,
  staffRatio: json['staffRatio'] as String,
  pricePerDay: (json['pricePerDay'] as num).toInt(),
  pricePerMonth: (json['pricePerMonth'] as num).toInt(),
  bedsLeft: (json['bedsLeft'] as num).toInt(),
  services: (json['services'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  scores: (json['scores'] as List<dynamic>)
      .map((e) => ScoreItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  partnerId: json['partnerId'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  about: json['about'] as String? ?? '',
  roomTypes:
      (json['roomTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$CentreToJson(_Centre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'locality': instance.locality,
  'city': instance.city,
  'photo': instance.photo,
  'photoCount': instance.photoCount,
  'rating': instance.rating,
  'reviews': instance.reviews,
  'since': instance.since,
  'licence': instance.licence,
  'staffRatio': instance.staffRatio,
  'pricePerDay': instance.pricePerDay,
  'pricePerMonth': instance.pricePerMonth,
  'bedsLeft': instance.bedsLeft,
  'services': instance.services,
  'scores': instance.scores,
  'partnerId': instance.partnerId,
  'phone': instance.phone,
  'about': instance.about,
  'roomTypes': instance.roomTypes,
  'photos': instance.photos,
};

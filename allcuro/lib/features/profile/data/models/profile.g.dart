// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  name: json['name'] as String,
  initials: json['initials'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String,
  verified: json['verified'] as bool,
  menuRows: (json['menuRows'] as List<dynamic>)
      .map((e) => ProfileMenuRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'name': instance.name,
  'initials': instance.initials,
  'phone': instance.phone,
  'email': instance.email,
  'verified': instance.verified,
  'menuRows': instance.menuRows,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Equipment _$EquipmentFromJson(Map<String, dynamic> json) => _Equipment(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  photo: json['photo'] as String,
  perDay: (json['perDay'] as num).toInt(),
  perMonth: (json['perMonth'] as num).toInt(),
  deposit: (json['deposit'] as num).toInt(),
  condition: json['condition'] as String,
  availableIn: json['availableIn'] as String,
  description: json['description'] as String? ?? '',
  features:
      (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  inStock: json['inStock'] as bool? ?? true,
);

Map<String, dynamic> _$EquipmentToJson(_Equipment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'photo': instance.photo,
      'perDay': instance.perDay,
      'perMonth': instance.perMonth,
      'deposit': instance.deposit,
      'condition': instance.condition,
      'availableIn': instance.availableIn,
      'description': instance.description,
      'features': instance.features,
      'inStock': instance.inStock,
    };

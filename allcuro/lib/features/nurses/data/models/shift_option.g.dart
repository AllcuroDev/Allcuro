// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftOption _$ShiftOptionFromJson(Map<String, dynamic> json) => _ShiftOption(
  label: json['label'] as String,
  price: (json['price'] as num).toInt(),
  available: json['available'] as bool,
  unit: json['unit'] as String? ?? '',
  mrp: (json['mrp'] as num?)?.toInt() ?? 0,
  serviceId: json['serviceId'] as String?,
);

Map<String, dynamic> _$ShiftOptionToJson(_ShiftOption instance) =>
    <String, dynamic>{
      'label': instance.label,
      'price': instance.price,
      'available': instance.available,
      'unit': instance.unit,
      'mrp': instance.mrp,
      'serviceId': instance.serviceId,
    };

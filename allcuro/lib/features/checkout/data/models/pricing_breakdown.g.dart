// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricing_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PricingBreakdown _$PricingBreakdownFromJson(Map<String, dynamic> json) =>
    _PricingBreakdown(
      base: (json['base'] as num).toInt(),
      discount: (json['discount'] as num).toInt(),
      fee: (json['fee'] as num).toInt(),
      gst: (json['gst'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PricingBreakdownToJson(_PricingBreakdown instance) =>
    <String, dynamic>{
      'base': instance.base,
      'discount': instance.discount,
      'fee': instance.fee,
      'gst': instance.gst,
      'total': instance.total,
    };

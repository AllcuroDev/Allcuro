// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScoreItem _$ScoreItemFromJson(Map<String, dynamic> json) => _ScoreItem(
  label: json['label'] as String,
  value: (json['value'] as num).toDouble(),
);

Map<String, dynamic> _$ScoreItemToJson(_ScoreItem instance) =>
    <String, dynamic>{'label': instance.label, 'value': instance.value};

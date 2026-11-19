import 'package:freezed_annotation/freezed_annotation.dart';

part 'score_item.freezed.dart';
part 'score_item.g.dart';

@freezed
abstract class ScoreItem with _$ScoreItem {
  const factory ScoreItem({required String label, required double value}) = _ScoreItem;

  factory ScoreItem.fromJson(Map<String, dynamic> json) => _$ScoreItemFromJson(json);
}

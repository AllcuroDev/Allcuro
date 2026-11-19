import 'package:freezed_annotation/freezed_annotation.dart';

import 'score_item.dart';

part 'centre.freezed.dart';
part 'centre.g.dart';

@freezed
abstract class Centre with _$Centre {
  const factory Centre({
    required String id,
    required String name,
    required String type,
    required String locality,
    required String city,
    required String photo,
    required int photoCount,
    required double rating,
    required int reviews,
    required int since,
    required String licence,
    required String staffRatio,
    required int pricePerDay,
    required int pricePerMonth,
    required int bedsLeft,
    required List<String> services,
    required List<ScoreItem> scores,
    @Default('') String partnerId,
    @Default('') String phone,
    @Default('') String about,
    @Default(<String>[]) List<String> roomTypes,
    @Default(<String>[]) List<String> photos,
  }) = _Centre;

  factory Centre.fromJson(Map<String, dynamic> json) => _$CentreFromJson(json);
}

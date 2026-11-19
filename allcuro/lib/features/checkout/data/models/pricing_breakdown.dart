import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricing_breakdown.freezed.dart';
part 'pricing_breakdown.g.dart';

@freezed
abstract class PricingBreakdown with _$PricingBreakdown {
  const factory PricingBreakdown({
    required int base,
    required int discount,
    required int fee,
    required int gst,
    required int total,
  }) = _PricingBreakdown;

  factory PricingBreakdown.fromJson(Map<String, dynamic> json) =>
      _$PricingBreakdownFromJson(json);
}

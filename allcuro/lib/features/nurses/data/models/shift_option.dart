import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_option.freezed.dart';
part 'shift_option.g.dart';

@freezed
abstract class ShiftOption with _$ShiftOption {
  const factory ShiftOption({
    required String label,
    required int price,
    required bool available,

    /// 'per visit', 'per shift', 'per day'… (partner_offerings.unit).
    @Default('') String unit,

    /// Price before the admin's discount; 0 when there is none.
    @Default(0) int mrp,
    String? serviceId,
  }) = _ShiftOption;

  factory ShiftOption.fromJson(Map<String, dynamic> json) => _$ShiftOptionFromJson(json);
}

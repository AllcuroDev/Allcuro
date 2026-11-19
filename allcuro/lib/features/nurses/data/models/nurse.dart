import 'package:freezed_annotation/freezed_annotation.dart';

import 'employment.dart';
import 'shift_option.dart';

export 'employment.dart';

part 'nurse.freezed.dart';
part 'nurse.g.dart';

@freezed
abstract class Nurse with _$Nurse {
  const factory Nurse({
    required String id,
    required String name,
    /// Photo URL from Supabase storage; '' when the partner has none.
    required String photo,
    required String allcuroId,
    required String level,
    required int experience,
    required String city,
    required List<String> languages,
    required List<String> tags,
    required double rating,
    required int reviews,
    required List<String> highlights,
    required List<ShiftOption> shifts,
    required Employment employment,

    /// nurse | doctor | physiotherapist | caregiver (partners.kind).
    @Default('nurse') String kind,

    /// partners.id — the uuid behind the URL slug in [id].
    @Default('') String partnerId,
    @Default('') String bio,
    @Default(true) bool available,
  }) = _Nurse;

  factory Nurse.fromJson(Map<String, dynamic> json) => _$NurseFromJson(json);
}

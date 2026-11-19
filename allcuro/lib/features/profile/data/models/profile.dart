import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile_menu_row.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String name,
    required String initials,
    required String phone,
    required String email,
    required bool verified,
    required List<ProfileMenuRow> menuRows,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}

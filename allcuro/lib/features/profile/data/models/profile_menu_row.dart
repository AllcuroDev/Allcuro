import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_menu_row.freezed.dart';
part 'profile_menu_row.g.dart';

/// [iconKey] is resolved to an [IconData] in the presentation layer, keeping
/// this model free of Flutter/Material dependencies.
@freezed
abstract class ProfileMenuRow with _$ProfileMenuRow {
  const factory ProfileMenuRow({
    required String iconKey,
    required String label,
    required String hint,
  }) = _ProfileMenuRow;

  factory ProfileMenuRow.fromJson(Map<String, dynamic> json) => _$ProfileMenuRowFromJson(json);
}

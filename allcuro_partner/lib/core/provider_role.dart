/// Which side of the ALLCURO Partner app the signed-in user is using.
/// Set once at login/onboarding (see `role_select_screen.dart`) and then
/// threaded through the app to pick the right shell tabs and home screen.
///
/// [clinician] covers doctors and physiotherapists. They have their own
/// sign-up wizard but share the nurse dashboard (home / requests / schedule)
/// afterwards, since their work is also visit-based.
enum ProviderRole { nurse, clinician, centre }

extension ProviderRoleX on ProviderRole {
  /// Whether this role lands in the visit-based `/nurse/...` shell.
  bool get usesNurseShell => this != ProviderRole.centre;
}

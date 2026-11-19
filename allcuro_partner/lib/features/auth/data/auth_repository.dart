import '../../../core/provider_role.dart';
import '../../../core/verification_status.dart';
import '../../identity/data/verified_identity.dart';
import 'auth_service.dart';

/// Signed-in state: whether there's a session at all, which
/// [ProviderRole] (if any) that account has picked, and how far each
/// role's sign-up wizard has gotten. `app_router.dart` redirects between
/// welcome / phone-auth / role-select / sign-up / the right shell based on
/// this. Both verification statuses are carried regardless of the active
/// role — cheap to load together, and it means switching roles never
/// requires a second round-trip to find out where that role's onboarding
/// left off.
class AuthSession {
  final bool isLoggedIn;
  final ProviderRole? role;
  final NurseVerificationStatus nurseVerificationStatus;

  /// Doctor / physiotherapist onboarding — same lifecycle as a nurse's.
  final NurseVerificationStatus clinicianVerificationStatus;
  final CentreVerificationStatus centreVerificationStatus;

  /// Aadhaar + registration proved at sign-up, per visit-based role. Null
  /// until that role has been through the identity verification step.
  final VerifiedIdentity? nurseIdentity;
  final VerifiedIdentity? clinicianIdentity;

  /// The centre's name from its sign-up (or `public.partners`). Null until
  /// the centre wizard has been submitted.
  final String? centreName;

  /// When ALLCURO scheduled the centre's site visit — null until an admin
  /// has actually set one.
  final DateTime? centreSiteVisitAt;

  const AuthSession({
    required this.isLoggedIn,
    this.role,
    this.nurseVerificationStatus = NurseVerificationStatus.incomplete,
    this.clinicianVerificationStatus = NurseVerificationStatus.incomplete,
    this.centreVerificationStatus = CentreVerificationStatus.incomplete,
    this.nurseIdentity,
    this.clinicianIdentity,
    this.centreName,
    this.centreSiteVisitAt,
  });

  static const initial = AuthSession(isLoggedIn: false);

  /// Status for whichever visit-based role (nurse or clinician) is active —
  /// what the shared nurse dashboard and profile screens should read.
  NurseVerificationStatus get practitionerVerificationStatus =>
      role == ProviderRole.clinician ? clinicianVerificationStatus : nurseVerificationStatus;

  /// Verified identity for whichever visit-based role is active.
  VerifiedIdentity? get practitionerIdentity =>
      role == ProviderRole.clinician ? clinicianIdentity : nurseIdentity;

  /// The active partner's own name — never a placeholder person. Falls back
  /// to a neutral label when sign-up hasn't captured a name yet.
  /// Up to two initials of [displayName], for the header avatar.
  String get initials {
    final letters = displayName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return letters.isEmpty ? 'P' : letters;
  }

  String get displayName {
    if (role == ProviderRole.centre) return centreName ?? 'Your centre';
    final name = practitionerIdentity?.fullName.trim() ?? '';
    return name.isEmpty ? 'Partner' : name;
  }

  /// Whether the active role must still verify registration + Aadhaar. This
  /// comes before the sign-up wizard, which prefills from the result.
  bool get identityPending => role != null && role!.usesNurseShell && practitionerIdentity == null;

  /// Whether the active role still has its basic sign-up wizard to finish.
  bool get signupIncomplete => switch (role) {
        ProviderRole.centre => centreVerificationStatus == CentreVerificationStatus.incomplete,
        ProviderRole.nurse || ProviderRole.clinician =>
          practitionerVerificationStatus == NurseVerificationStatus.incomplete,
        null => false,
      };

  AuthSession copyWith({
    NurseVerificationStatus? nurseVerificationStatus,
    NurseVerificationStatus? clinicianVerificationStatus,
    CentreVerificationStatus? centreVerificationStatus,
    VerifiedIdentity? nurseIdentity,
    VerifiedIdentity? clinicianIdentity,
  }) {
    return AuthSession(
      isLoggedIn: isLoggedIn,
      role: role,
      nurseVerificationStatus: nurseVerificationStatus ?? this.nurseVerificationStatus,
      clinicianVerificationStatus: clinicianVerificationStatus ?? this.clinicianVerificationStatus,
      centreVerificationStatus: centreVerificationStatus ?? this.centreVerificationStatus,
      nurseIdentity: nurseIdentity ?? this.nurseIdentity,
      clinicianIdentity: clinicianIdentity ?? this.clinicianIdentity,
      centreName: centreName,
      centreSiteVisitAt: centreSiteVisitAt,
    );
  }
}

/// Domain layer over [AuthService] — `AuthViewModel` talks to this, never
/// to `SharedPreferences` directly.
class AuthRepository {
  final AuthService _service;

  AuthRepository(this._service);

  /// [syncFromServer] pulls admin-set statuses from `public.partners` first —
  /// done on app start and right after sign-in, not after every local change.
  Future<AuthSession> loadSession({bool syncFromServer = false}) async {
    final loggedIn = await _service.isLoggedIn();
    if (!loggedIn) return AuthSession.initial;
    if (syncFromServer) await _service.syncStatusesFromServer();
    return AuthSession(
      isLoggedIn: true,
      role: await _service.getPersistedRole(),
      nurseVerificationStatus: await _service.getNurseVerificationStatus(),
      clinicianVerificationStatus: await _service.getClinicianVerificationStatus(),
      centreVerificationStatus: await _service.getCentreVerificationStatus(),
      nurseIdentity: await _service.getNurseIdentity(),
      clinicianIdentity: await _service.getClinicianIdentity(),
      centreName: await _service.getCentreName(),
      centreSiteVisitAt: await _service.getCentreSiteVisitAt(),
    );
  }

  Future<void> sendOtp(String phone) => _service.sendOtp(phone);

  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    await _service.verifyOtp(phone: phone, otp: otp);
    return loadSession(syncFromServer: true);
  }

  Future<AuthSession> selectRole(ProviderRole role) async {
    await _service.saveRole(role);
    return loadSession();
  }

  Future<AuthSession> setNurseVerificationStatus(NurseVerificationStatus status) async {
    await _service.setNurseVerificationStatus(status);
    return loadSession();
  }

  Future<AuthSession> setClinicianVerificationStatus(NurseVerificationStatus status) async {
    await _service.setClinicianVerificationStatus(status);
    return loadSession();
  }

  Future<AuthSession> setCentreVerificationStatus(CentreVerificationStatus status) async {
    await _service.setCentreVerificationStatus(status);
    return loadSession();
  }

  Future<AuthSession> saveCentreName(String name) async {
    await _service.setCentreName(name);
    return loadSession();
  }

  Future<AuthSession> saveIdentity(ProviderRole role, VerifiedIdentity identity) async {
    if (role == ProviderRole.clinician) {
      await _service.setClinicianIdentity(identity);
    } else {
      await _service.setNurseIdentity(identity);
    }
    return loadSession();
  }

  Future<AuthSession> logout() async {
    await _service.logout();
    return AuthSession.initial;
  }
}

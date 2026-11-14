import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/phone_auth.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/provider_role.dart';
import '../../../core/verification_status.dart';
import '../../identity/data/verified_identity.dart';

/// Thrown by [AuthService.sendOtp] / [AuthService.verifyOtp] on invalid
/// input. The message is shown directly to the user by `PhoneAuthScreen`.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Partner sign-in: phone OTP through Supabase Auth ([PhoneAuth]) — the same
/// accounts the partner web portal uses. SharedPreferences keeps the chosen
/// [ProviderRole], wizard progress and identity so screens render instantly;
/// the Supabase session decides whether the partner is signed in, and the
/// admin-controlled status of any role already saved in `public.partners`
/// overrides the cached one (see [syncStatusesFromServer]).
///
/// Built without Supabase keys, it runs in demo mode (code [demoOtp], local only).
class AuthService {
  static const _loggedInKey = 'auth.logged_in';
  static const _phoneKey = 'auth.phone';
  static const _roleKey = 'auth.role';
  static const _nurseStatusKey = 'auth.nurse_verification_status';
  static const _clinicianStatusKey = 'auth.clinician_verification_status';
  static const _centreStatusKey = 'auth.centre_verification_status';
  static const _nurseIdentityKey = 'auth.nurse_identity';
  static const _clinicianIdentityKey = 'auth.clinician_identity';

  static const demoOtp = PhoneAuth.demoOtp;
  static bool get isDemo => PhoneAuth.isDemo;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (!SupabaseConfig.isConfigured) return prefs.getBool(_loggedInKey) ?? false;
    final loggedIn = PhoneAuth.hasSession;
    if (loggedIn) {
      await prefs.setBool(_loggedInKey, true);
    } else {
      await prefs.remove(_loggedInKey);
    }
    return loggedIn;
  }

  Future<void> sendOtp(String phone) async {
    try {
      await PhoneAuth.requestOtp(phone);
    } on PhoneAuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    try {
      await PhoneAuth.confirmOtp(phone, otp);
    } on PhoneAuthException catch (e) {
      throw AuthException(e.message);
    }
    final prefs = await SharedPreferences.getInstance();
    final digits = PhoneAuth.digitsOf(phone);
    // A different number is a different account: start from a clean cache.
    if (prefs.getString(_phoneKey) != digits) await _clearCache(prefs);
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_phoneKey, digits);
  }

  /// Copies the status of every role this account has saved in
  /// `public.partners` (approved / rejected / … — set by the admin) into the
  /// cache. Roles with no row yet keep their local wizard progress.
  Future<void> syncStatusesFromServer() async {
    final client = supabaseOrNull;
    final userId = PhoneAuth.currentUserId;
    if (client == null || userId == null) return;
    final List<dynamic> rows;
    try {
      rows = await client.from('partners').select('role, status').eq('user_id', userId);
    } catch (_) {
      return; // Offline — keep the cached statuses.
    }
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final status = row['status'] as String? ?? 'incomplete';
      switch (row['role']) {
        case 'centre':
          await setCentreVerificationStatus(_centreStatusFromDb(status));
        case 'clinician':
          await setClinicianVerificationStatus(_nurseStatusFromDb(status));
        case 'nurse':
          await setNurseVerificationStatus(_nurseStatusFromDb(status));
      }
    }
    if (await getPersistedRole() == null && rows.length == 1) {
      final only = (rows.first as Map<String, dynamic>)['role'];
      for (final role in ProviderRole.values) {
        if (role.name == only) await saveRole(role);
      }
    }
  }

  static NurseVerificationStatus _nurseStatusFromDb(String status) => switch (status) {
        'onboarding' => NurseVerificationStatus.onboarding,
        'under_review' || 'site_visit_scheduled' => NurseVerificationStatus.underReview,
        'approved' => NurseVerificationStatus.verified,
        _ => _byName(NurseVerificationStatus.values, status) ?? NurseVerificationStatus.incomplete,
      };

  static CentreVerificationStatus _centreStatusFromDb(String status) => switch (status) {
        'onboarding' => CentreVerificationStatus.onboarding,
        'under_review' => CentreVerificationStatus.pendingReview,
        'site_visit_scheduled' => CentreVerificationStatus.siteVisitScheduled,
        'approved' => CentreVerificationStatus.verified,
        _ => _byName(CentreVerificationStatus.values, status) ?? CentreVerificationStatus.incomplete,
      };

  static T? _byName<T extends Enum>(List<T> values, String name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  Future<ProviderRole?> getPersistedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roleKey);
    for (final role in ProviderRole.values) {
      if (role.name == raw) return role;
    }
    return null;
  }

  Future<void> saveRole(ProviderRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  Future<NurseVerificationStatus> getNurseVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_nurseStatusKey);
    for (final status in NurseVerificationStatus.values) {
      if (status.name == raw) return status;
    }
    return NurseVerificationStatus.incomplete;
  }

  Future<void> setNurseVerificationStatus(NurseVerificationStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nurseStatusKey, status.name);
  }

  Future<NurseVerificationStatus> getClinicianVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clinicianStatusKey);
    for (final status in NurseVerificationStatus.values) {
      if (status.name == raw) return status;
    }
    return NurseVerificationStatus.incomplete;
  }

  Future<void> setClinicianVerificationStatus(NurseVerificationStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clinicianStatusKey, status.name);
  }

  Future<CentreVerificationStatus> getCentreVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_centreStatusKey);
    for (final status in CentreVerificationStatus.values) {
      if (status.name == raw) return status;
    }
    return CentreVerificationStatus.incomplete;
  }

  Future<void> setCentreVerificationStatus(CentreVerificationStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_centreStatusKey, status.name);
  }

  Future<VerifiedIdentity?> getNurseIdentity() => _readIdentity(_nurseIdentityKey);

  Future<void> setNurseIdentity(VerifiedIdentity identity) => _writeIdentity(_nurseIdentityKey, identity);

  Future<VerifiedIdentity?> getClinicianIdentity() => _readIdentity(_clinicianIdentityKey);

  Future<void> setClinicianIdentity(VerifiedIdentity identity) =>
      _writeIdentity(_clinicianIdentityKey, identity);

  Future<VerifiedIdentity?> _readIdentity(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return VerifiedIdentity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Unreadable (e.g. an older shape) — treat as not yet verified.
      return null;
    }
  }

  Future<void> _writeIdentity(String key, VerifiedIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(identity.toJson()));
  }

  Future<void> logout() async {
    await PhoneAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await _clearCache(prefs);
  }

  Future<void> _clearCache(SharedPreferences prefs) async {
    await prefs.remove(_loggedInKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nurseStatusKey);
    await prefs.remove(_clinicianStatusKey);
    await prefs.remove(_centreStatusKey);
    await prefs.remove(_nurseIdentityKey);
    await prefs.remove(_clinicianIdentityKey);
  }
}

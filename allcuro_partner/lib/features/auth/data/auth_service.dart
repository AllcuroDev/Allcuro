import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/provider_role.dart';
import '../../../core/verification_status.dart';

/// Thrown by [AuthService.sendOtp] / [AuthService.verifyOtp] on invalid
/// input. The message is shown directly to the user by `PhoneAuthScreen`.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Local mock auth "backend" — persists a logged-in flag and the chosen
/// [ProviderRole] via [SharedPreferences] so a signed-in account isn't
/// asked to verify their phone or pick a role on every launch. No SMS is
/// actually sent; [verifyOtp] just checks against [demoOtp]. Swap both
/// methods' bodies for real OTP-provider API calls once there's a backend
/// to hit — the persistence keys/shape can stay the same.
class AuthService {
  static const _loggedInKey = 'auth.logged_in';
  static const _roleKey = 'auth.role';
  static const _nurseStatusKey = 'auth.nurse_verification_status';
  static const _clinicianStatusKey = 'auth.clinician_verification_status';
  static const _centreStatusKey = 'auth.centre_verification_status';

  /// The only code [verifyOtp] accepts, since there's no real SMS backend
  /// yet. Shown to the user on the OTP step so the mock flow is usable.
  static const demoOtp = '123456';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<ProviderRole?> getPersistedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roleKey);
    for (final role in ProviderRole.values) {
      if (role.name == raw) return role;
    }
    return null;
  }

  Future<void> sendOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_digitsOf(phone).length != 10) {
      throw const AuthException('Enter a valid 10-digit phone number.');
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (otp != demoOtp) {
      throw const AuthException('Incorrect code. Please try again.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nurseStatusKey);
    await prefs.remove(_clinicianStatusKey);
    await prefs.remove(_centreStatusKey);
  }

  String _digitsOf(String phone) => phone.replaceAll(RegExp(r'\D'), '');
}

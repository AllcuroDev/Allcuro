import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/provider_role.dart';
import '../../../core/verification_status.dart';
import '../../identity/data/verified_identity.dart';
import '../data/auth_repository.dart';
import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authServiceProvider));
});

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, AuthSession>(AuthViewModel.new);

/// Drives login state and which [ProviderRole] the signed-in account uses.
/// `app_router.dart` watches this (via a `ChangeNotifier` bridge) to
/// redirect between welcome, phone-auth, role-select, and the right shell.
class AuthViewModel extends AsyncNotifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthSession> build() {
    // Pick up the admin's decision (approved / changes requested) whenever
    // the partner comes back to the app.
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (state.valueOrNull?.isLoggedIn ?? false) refreshFromServer();
      },
    );
    ref.onDispose(lifecycle.dispose);
    return _repository.loadSession(syncFromServer: true);
  }

  /// Called by `PhoneAuthViewModel` once OTP verification succeeds — the
  /// session was already persisted by the repository, this just makes the
  /// in-memory state (and therefore the router redirect) reflect it.
  void applySession(AuthSession session) {
    state = AsyncData(session);
  }

  Future<void> selectRole(ProviderRole role) async {
    state = await AsyncValue.guard(() => _repository.selectRole(role));
  }

  /// Called once registration + Aadhaar verification succeed for the active
  /// visit-based role — the router then moves on to the sign-up wizard.
  Future<void> saveIdentity(VerifiedIdentity identity) async {
    final role = state.valueOrNull?.role;
    if (role == null) return;
    state = await AsyncValue.guard(() => _repository.saveIdentity(role, identity));
  }

  /// Called when the nurse sign-up wizard is submitted. Admin approval
  /// comes from `public.partners` (see `AuthService.syncStatusesFromServer`);
  /// only demo builds (no Supabase keys) can advance it locally.
  Future<void> setNurseVerificationStatus(NurseVerificationStatus status) async {
    state = await AsyncValue.guard(() => _repository.setNurseVerificationStatus(status));
  }

  /// Same as [setNurseVerificationStatus], for the doctor / physiotherapist
  /// sign-up wizard.
  Future<void> setClinicianVerificationStatus(NurseVerificationStatus status) async {
    state = await AsyncValue.guard(() => _repository.setClinicianVerificationStatus(status));
  }

  /// Sets the status for whichever visit-based role (nurse or clinician) is
  /// active — used by the shared nurse dashboard & profile screens.
  Future<void> setPractitionerVerificationStatus(NurseVerificationStatus status) {
    return state.valueOrNull?.role == ProviderRole.clinician
        ? setClinicianVerificationStatus(status)
        : setNurseVerificationStatus(status);
  }

  /// Same as [setNurseVerificationStatus], for the centre sign-up wizard.
  Future<void> setCentreVerificationStatus(CentreVerificationStatus status) async {
    state = await AsyncValue.guard(() => _repository.setCentreVerificationStatus(status));
  }

  /// Remembers the centre name entered in the centre sign-up wizard.
  Future<void> saveCentreName(String name) async {
    state = await AsyncValue.guard(() => _repository.saveCentreName(name));
  }

  /// Re-reads admin-set statuses (and site-visit time) from Supabase.
  Future<void> refreshFromServer() async {
    state = await AsyncValue.guard(() => _repository.loadSession(syncFromServer: true));
  }

  Future<void> logout() async {
    state = await AsyncValue.guard(_repository.logout);
  }
}

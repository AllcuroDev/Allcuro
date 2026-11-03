import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/provider_role.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../clinician/presentation/signup/clinician_signup_view_model.dart';
import '../data/identity_service.dart';
import '../data/verified_identity.dart';

final identityServiceProvider = Provider<IdentityService>((ref) => IdentityService());

/// Everything the two verification steps collect, mutated in place by the
/// step widgets (same pattern as the sign-up wizards' data classes).
class IdentityFormData {
  /// Doctors / physiotherapists only — picks the register to check against.
  ClinicianProfession? profession;
  String registrationNumber = '';
  String? council;
  RegistryRecord? registry;

  /// Digits only, no spaces.
  String aadhaar = '';
  bool aadhaarConsent = false;
  bool otpSent = false;
  String otp = '';
  AadhaarProfile? aadhaarProfile;
}

class IdentityVerificationState {
  final int stepIndex;
  final IdentityFormData data;
  final bool isBusy;
  final String? error;

  const IdentityVerificationState({required this.stepIndex, required this.data, this.isBusy = false, this.error});

  IdentityVerificationState copyWith({int? stepIndex, bool? isBusy, String? error, bool clearError = false}) {
    return IdentityVerificationState(
      stepIndex: stepIndex ?? this.stepIndex,
      data: data,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final identityVerificationViewModelProvider =
    NotifierProvider.autoDispose<IdentityVerificationViewModel, IdentityVerificationState>(
      IdentityVerificationViewModel.new,
    );

/// Drives `IdentityVerificationScreen`: 1) professional registration — NUID
/// for nurses, council registration number for doctors / physiotherapists —
/// then 2) Aadhaar e-KYC via OTP. On success the combined [VerifiedIdentity]
/// is saved to the session, and the router moves on to the sign-up wizard.
class IdentityVerificationViewModel extends AutoDisposeNotifier<IdentityVerificationState> {
  static const stepCount = 2;

  IdentityService get _service => ref.read(identityServiceProvider);

  bool get isClinician => ref.read(authViewModelProvider).valueOrNull?.role == ProviderRole.clinician;

  @override
  IdentityVerificationState build() => IdentityVerificationState(stepIndex: 0, data: IdentityFormData());

  void back() {
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1, clearError: true);
    }
  }

  void next() {
    if (state.stepIndex < stepCount - 1) {
      state = state.copyWith(stepIndex: state.stepIndex + 1, clearError: true);
    }
  }

  /// Call after mutating [IdentityFormData] fields in place, so watchers
  /// rebuild with the fresh values.
  void touch() => state = state.copyWith(clearError: true);

  /// Any change to what identifies the registration invalidates a previous
  /// lookup result.
  void editRegistration(void Function(IdentityFormData data) change) {
    change(state.data);
    state.data.registry = null;
    touch();
  }

  /// Editing the Aadhaar number after an OTP went out starts that part over.
  void editAadhaar(String digits) {
    final data = state.data;
    data.aadhaar = digits;
    data.otpSent = false;
    data.otp = '';
    data.aadhaarProfile = null;
    touch();
  }

  Future<void> verifyRegistration() async {
    final data = state.data;
    await _run(() async {
      data.registry = isClinician
          ? await _service.verifyCouncilRegistration(
              isPhysiotherapist: data.profession == ClinicianProfession.physiotherapist,
              registrationNumber: data.registrationNumber,
              council: data.council!,
            )
          : await _service.verifyNuid(data.registrationNumber);
    });
  }

  Future<void> sendOtp() async {
    final data = state.data;
    await _run(() async {
      await _service.sendAadhaarOtp(data.aadhaar);
      data.otpSent = true;
      data.otp = '';
    });
  }

  Future<void> verifyOtp() async {
    final data = state.data;
    await _run(() async {
      final profile = await _service.verifyAadhaarOtp(aadhaar: data.aadhaar, otp: data.otp, isClinician: isClinician);
      final registeredName = data.registry?.registeredName ?? '';
      if (_normalise(profile.name) != _normalise(registeredName)) {
        throw StateError(
          'The name on your Aadhaar (${profile.name}) does not match your '
          'registration ($registeredName). Contact support to resolve this.',
        );
      }
      data.aadhaarProfile = profile;
    });
  }

  /// Saves the verified identity; the router redirect takes it from there.
  Future<void> finish() async {
    final data = state.data;
    final registry = data.registry;
    final profile = data.aadhaarProfile;
    if (registry == null || profile == null) return;

    state = state.copyWith(isBusy: true, clearError: true);
    await ref
        .read(authViewModelProvider.notifier)
        .saveIdentity(
          VerifiedIdentity(
            fullName: profile.name,
            dob: profile.dob,
            gender: profile.gender,
            address: profile.address,
            aadhaarLast4: data.aadhaar.substring(data.aadhaar.length - 4),
            registrationLabel: registrationLabel(),
            registrationNumber: data.registrationNumber.trim().toUpperCase(),
            council: registry.council,
            qualification: registry.qualification,
            profession: data.profession?.name,
          ),
        );
    // On success the router redirect replaces this screen (and disposes this
    // notifier), so only a failed save needs the busy state cleared.
    if (ref.read(authViewModelProvider).hasError) {
      state = state.copyWith(isBusy: false, error: 'Could not save your verification. Please try again.');
    }
  }

  /// How the registration number is labelled for the active role.
  String registrationLabel() {
    if (!isClinician) return 'NUID';
    return state.data.profession == ClinicianProfession.physiotherapist ? 'Physio Reg. No.' : 'Medical Reg. No.';
  }

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isBusy: false);
    } on Object catch (e) {
      state = state.copyWith(isBusy: false, error: e is StateError ? e.message : e.toString());
    }
  }

  String _normalise(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

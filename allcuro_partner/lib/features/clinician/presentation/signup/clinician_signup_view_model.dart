import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/verification_status.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../identity/data/verified_identity.dart';

/// Which kind of clinician is signing up — drives the qualification,
/// specialisation and council options shown in the wizard.
enum ClinicianProfession { doctor, physiotherapist }

/// Every field the doctor / physiotherapist sign-up collects.
class ClinicianSignupData {
  ClinicianProfession? profession;
  String fullName = '';
  DateTime? dob;
  String? gender;
  String address = '';
  String city = 'Bengaluru';

  String? qualification;
  final Set<String> specialisations = {};
  String registrationNumber = '';
  String council = '';
  String experienceYears = '';

  bool backgroundConsent = false;

  /// Overwrites the fields that came from Aadhaar / the council register —
  /// the wizard shows these locked.
  void applyIdentity(VerifiedIdentity identity) {
    for (final p in ClinicianProfession.values) {
      if (p.name == identity.profession) profession = p;
    }
    fullName = identity.fullName;
    dob = identity.dob;
    gender = identity.gender;
    address = identity.address;
    qualification = identity.qualification;
    registrationNumber = identity.registrationNumber;
    council = identity.council;
  }
}

class ClinicianSignupState {
  final int stepIndex;
  final ClinicianSignupData data;
  final bool isSubmitting;

  const ClinicianSignupState({
    required this.stepIndex,
    required this.data,
    this.isSubmitting = false,
  });

  ClinicianSignupState copyWith({int? stepIndex, bool? isSubmitting}) {
    return ClinicianSignupState(
      stepIndex: stepIndex ?? this.stepIndex,
      data: data,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final clinicianSignupViewModelProvider =
    NotifierProvider.autoDispose<ClinicianSignupViewModel, ClinicianSignupState>(ClinicianSignupViewModel.new);

/// Drives the doctor / physiotherapist sign-up wizard (`ClinicianSignupScreen`).
/// Mirrors the nurse flow's 3 steps: Basic Details -> Qualification & Reg ->
/// Background Consent & Submit, after identity verification has prefilled
/// (and locked) profession, name, DOB, gender, address, qualification and
/// registration number. Every step can be skipped. Documents, bank &
/// availability are completed progressively from the (shared) nurse Home &
/// Profile screens.
class ClinicianSignupViewModel extends AutoDisposeNotifier<ClinicianSignupState> {
  static const stepCount = 3;

  @override
  ClinicianSignupState build() {
    final data = ClinicianSignupData();
    final identity = ref.read(authViewModelProvider).valueOrNull?.practitionerIdentity;
    if (identity != null) data.applyIdentity(identity);
    return ClinicianSignupState(stepIndex: 0, data: data);
  }

  void next() {
    if (state.stepIndex < stepCount - 1) {
      state = state.copyWith(stepIndex: state.stepIndex + 1);
    }
  }

  void back() {
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1);
    }
  }

  /// Call after mutating [ClinicianSignupData] fields in place, so watchers
  /// rebuild with the fresh values.
  void touch() => state = state.copyWith();

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true);
    await Future.delayed(const Duration(milliseconds: 600));
    await ref
        .read(authViewModelProvider.notifier)
        .setClinicianVerificationStatus(NurseVerificationStatus.onboarding);
    state = state.copyWith(isSubmitting: false);
  }
}

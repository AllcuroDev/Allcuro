import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/verification_status.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../identity/data/verified_identity.dart';

/// One of the 1–2 previous employer/supervisor contacts ALLCURO ops calls
/// during reference checks.
class ReferenceContact {
  String name;
  String relation;
  String phone;

  ReferenceContact({this.name = '', this.relation = '', this.phone = ''});

  bool get isComplete => name.trim().isNotEmpty && relation.trim().isNotEmpty && phone.trim().length == 10;
}

/// Every field the nurse sign-up & profile setup collects.
class NurseSignupData {
  String fullName = 'Priya Sharma';
  DateTime? dob = DateTime(1996, 5, 14);
  String? gender = 'Female';
  String city = 'Bengaluru';
  String address = 'Indiranagar 100ft Road';

  String? employmentType = 'Full-time';

  String? qualification = 'GNM';
  String registrationNumber = '';
  String council = '';
  String experienceYears = '5';
  String previousEmployer = 'Manipal Hospital';

  final Map<String, String?> documents = {
    'govt_id': null,
    'council_reg': null,
    'edu_certs': null,
    'pay_slip': null,
    'address_proof': null,
    'selfie': null,
  };

  final Map<String, String?> medicalDocuments = {'self_certificate': null, 'tb_report': null};

  bool policeConsent = true;

  final List<ReferenceContact> references = [ReferenceContact(), ReferenceContact()];

  final Set<String> skills = {'ICU / Critical Care', 'Tracheostomy Care', 'Post-Op Dressing'};

  String bankAccountHolder = '';
  String bankAccountNumber = '';
  String bankIfsc = '';

  String? interviewSlot;

  /// Overwrites the fields that came from Aadhaar / NUID — the wizard shows
  /// these locked.
  void applyIdentity(VerifiedIdentity identity) {
    fullName = identity.fullName;
    dob = identity.dob;
    gender = identity.gender;
    address = identity.address;
    qualification = identity.qualification;
    registrationNumber = identity.registrationNumber;
    council = identity.council;
  }
}

class NurseSignupState {
  final int stepIndex;
  final NurseSignupData data;
  final Set<String> uploadingIds;
  final bool isSubmitting;
  final String? error;

  const NurseSignupState({
    required this.stepIndex,
    required this.data,
    this.uploadingIds = const {},
    this.isSubmitting = false,
    this.error,
  });

  NurseSignupState copyWith({
    int? stepIndex,
    Set<String>? uploadingIds,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return NurseSignupState(
      stepIndex: stepIndex ?? this.stepIndex,
      data: data,
      uploadingIds: uploadingIds ?? this.uploadingIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final nurseSignupViewModelProvider =
    NotifierProvider.autoDispose<NurseSignupViewModel, NurseSignupState>(NurseSignupViewModel.new);

/// Drives the streamlined nurse sign-up wizard (`NurseSignupScreen`).
/// Essential 3-step sign-up: Basic Details -> Qualification & Reg -> Background Consent & Submit.
/// Runs after identity verification: name, DOB, gender, address, qualification and NUID are
/// prefilled from Aadhaar / the council register and locked. Every step can be skipped.
/// Remaining items (Document Vault, Medical Certs, References, Bank Account) are setup progressively
/// from the Nurse Home & Profile screen!
class NurseSignupViewModel extends AutoDisposeNotifier<NurseSignupState> {
  static const stepCount = 3;

  @override
  NurseSignupState build() {
    final data = NurseSignupData();
    final identity = ref.read(authViewModelProvider).valueOrNull?.practitionerIdentity;
    if (identity != null) data.applyIdentity(identity);
    return NurseSignupState(stepIndex: 0, data: data);
  }

  void next() {
    if (state.stepIndex < stepCount - 1) {
      state = state.copyWith(stepIndex: state.stepIndex + 1, clearError: true);
    }
  }

  void back() {
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1, clearError: true);
    }
  }

  /// Call after mutating [NurseSignupData] fields in place, so watchers
  /// rebuild with the fresh values.
  void touch() => state = state.copyWith();

  Future<void> mockUpload(Map<String, String?> target, String id, String fileName) async {
    state = state.copyWith(uploadingIds: {...state.uploadingIds, id});
    await Future.delayed(const Duration(milliseconds: 700));
    target[id] = fileName;
    final remaining = {...state.uploadingIds}..remove(id);
    state = state.copyWith(uploadingIds: remaining);
  }

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    await ref
        .read(authViewModelProvider.notifier)
        .setNurseVerificationStatus(NurseVerificationStatus.onboarding);
    state = state.copyWith(isSubmitting: false);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/verification_status.dart';
import '../../../auth/presentation/auth_view_model.dart';

class StaffMember {
  String name;
  String qualification;
  String role;

  StaffMember({this.name = '', this.qualification = '', this.role = ''});

  bool get isComplete =>
      name.trim().isNotEmpty && qualification.trim().isNotEmpty && role.trim().isNotEmpty;
}

/// Every field collected for Home Care Centre setup & onboarding.
class CentreSignupData {
  String businessEmail = '';
  String centreName = '';
  String? centreType;
  String yearEstablished = '';
  String? ownershipType;
  String staffRatio = '';
  String sampleFoodMenu = '';

  final Map<String, String?> documents = {
    'shop_act': null,
    'cea': null,
    'fire_noc': null,
    'bio_waste': null,
  };

  final List<StaffMember> staff = [StaffMember()];

  String? siteVisitSlot;

  String bankAccountHolder = '';
  String bankAccountNumber = '';
  String bankIfsc = '';
  String gstNumber = '';

  int photoCount = 0;
  String pricePerPackage = '';
  final Set<String> servicesIncluded = {};
  final Set<String> roomTypes = {};
}

class CentreSignupState {
  final int stepIndex;
  final CentreSignupData data;
  final Set<String> uploadingIds;
  final bool isSubmitting;
  final String? error;

  const CentreSignupState({
    required this.stepIndex,
    required this.data,
    this.uploadingIds = const {},
    this.isSubmitting = false,
    this.error,
  });

  CentreSignupState copyWith({
    int? stepIndex,
    Set<String>? uploadingIds,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return CentreSignupState(
      stepIndex: stepIndex ?? this.stepIndex,
      data: data,
      uploadingIds: uploadingIds ?? this.uploadingIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final centreSignupViewModelProvider =
    NotifierProvider.autoDispose<CentreSignupViewModel, CentreSignupState>(CentreSignupViewModel.new);

/// Streamlined 3-step centre sign-up wizard.
/// Remaining items (Document Vault, Staff Roster, Site Visit, Bank Payout, Bed & Room Listing Photos)
/// are setup progressively from Centre Home, Compliance Hub & Listing Management.
class CentreSignupViewModel extends AutoDisposeNotifier<CentreSignupState> {
  static const stepCount = 3;

  @override
  CentreSignupState build() => CentreSignupState(stepIndex: 0, data: CentreSignupData());

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

  void touch() => state = state.copyWith();

  void addStaffMember() {
    state.data.staff.add(StaffMember());
    touch();
  }

  void removeStaffMember(int index) {
    if (state.data.staff.length > 1) {
      state.data.staff.removeAt(index);
      touch();
    }
  }

  Future<void> mockUpload(Map<String, String?> target, String id, String fileName) async {
    state = state.copyWith(uploadingIds: {...state.uploadingIds, id});
    await Future.delayed(const Duration(milliseconds: 700));
    target[id] = fileName;
    final remaining = {...state.uploadingIds}..remove(id);
    state = state.copyWith(uploadingIds: remaining);
  }

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final auth = ref.read(authViewModelProvider.notifier);
    await auth.saveCentreName(state.data.centreName);
    await auth.setCentreVerificationStatus(CentreVerificationStatus.onboarding);
    state = state.copyWith(isSubmitting: false);
  }
}

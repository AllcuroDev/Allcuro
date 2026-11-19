import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/verification_status.dart';
import '../../centre/data/models/bed_slot.dart';
import '../../centre/data/models/equipment_item.dart';
import '../../centre/data/models/room.dart';
import '../../centre/data/models/staff_member.dart';
import 'auth_view_model.dart';

class BankAccountInfo {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final String accountType; // 'Current' | 'Savings'
  final String panNumber;
  final bool isVerified;

  const BankAccountInfo({
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.accountHolderName = '',
    this.accountType = 'Current Account',
    this.panNumber = '',
    this.isVerified = false,
  });

  static const empty = BankAccountInfo(
    bankName: '',
    accountNumber: '',
    ifscCode: '',
    accountHolderName: '',
    accountType: 'Current Account',
    panNumber: '',
    isVerified: false,
  );

  bool get isConfigured =>
      accountNumber.trim().isNotEmpty &&
      ifscCode.trim().isNotEmpty &&
      accountHolderName.trim().isNotEmpty;
}

class ComplianceDocItem {
  final String id;
  final String title;
  final String docType;
  final String fileName;
  final String expiry;
  final bool isUploaded;
  final bool isVerified;

  /// A required document type the partner hasn't uploaded yet. The titles
  /// are reference content; upload / verification state starts false.
  const ComplianceDocItem({
    required this.id,
    required this.title,
    required this.docType,
    this.fileName = '',
    this.expiry = 'Not uploaded yet',
    this.isUploaded = false,
    this.isVerified = false,
  });
}

/// Nurse document ids — [PartnerOnboardingState] derives setup progress from them.
const nurseHprDocId = 'nd-hpr';
const nurseDegreeDocId = 'nd-degree';
const nurseMedicalDocId = 'nd-medical';

/// Required document types (reference content) — all start not uploaded.
const _centreRequiredDocs = [
  ComplianceDocItem(id: 'cd-1', title: 'Clinical Establishment Act Licence (CEA)', docType: 'cea_license'),
  ComplianceDocItem(id: 'cd-2', title: 'Fire Safety NOC Certificate', docType: 'fire_noc'),
  ComplianceDocItem(id: 'cd-3', title: 'Biomedical Waste Authorisation', docType: 'biowaste_noc'),
  ComplianceDocItem(id: 'cd-4', title: 'Building & Ward Inspection Photos', docType: 'facility_photos'),
];

// Aadhaar and NUID / council registration are verified electronically at
// sign-up, so they aren't uploads here.
const _nurseRequiredDocs = [
  ComplianceDocItem(
    id: nurseHprDocId,
    title: 'Healthcare Professionals Registry (HPR / ABHA ID)',
    docType: 'hpr_registry',
  ),
  ComplianceDocItem(id: nurseDegreeDocId, title: 'Nursing Degree / GNM Diploma Certificate', docType: 'degree_certificate'),
  ComplianceDocItem(id: nurseMedicalDocId, title: 'Medical Fitness & TB Screening Report', docType: 'medical_fitness'),
];

class PartnerOnboardingState {
  final BankAccountInfo bankAccount;
  final List<Room> rooms;
  final List<StaffMember> staffMembers;
  final List<EquipmentItem> equipmentList;
  final List<ComplianceDocItem> centreComplianceDocs;
  final List<ComplianceDocItem> nurseDocs;
  final List<String> nurseSkills;
  final double nurseHourlyRate;
  final double nurseDailyRate;
  final bool nursePoliceConsentDone;

  const PartnerOnboardingState({
    required this.bankAccount,
    required this.rooms,
    required this.staffMembers,
    required this.equipmentList,
    required this.centreComplianceDocs,
    required this.nurseDocs,
    required this.nurseSkills,
    required this.nurseHourlyRate,
    required this.nurseDailyRate,
    required this.nursePoliceConsentDone,
  });

  /// A partner who hasn't added anything yet.
  static const initial = PartnerOnboardingState(
    bankAccount: BankAccountInfo.empty,
    rooms: [],
    staffMembers: [],
    equipmentList: [],
    centreComplianceDocs: _centreRequiredDocs,
    nurseDocs: _nurseRequiredDocs,
    nurseSkills: [],
    nurseHourlyRate: 0,
    nurseDailyRate: 0,
    nursePoliceConsentDone: false,
  );

  bool _nurseDocUploaded(String id) => nurseDocs.any((d) => d.id == id && d.isUploaded);

  // Calculate Centre Steps
  bool get centreEntityDone => true; // Finished at initial 3-step signup
  bool get centreDocsDone => centreComplianceDocs.where((d) => d.isUploaded).length >= 3;
  bool get centreBankDone => bankAccount.isConfigured;
  bool get centreRoomsDone => rooms.isNotEmpty;
  bool get centreStaffDone => staffMembers.isNotEmpty;
  bool get centreEquipmentDone => equipmentList.isNotEmpty;

  int get centreCompletedStepsCount {
    int c = 0;
    if (centreEntityDone) c++;
    if (centreDocsDone) c++;
    if (centreBankDone) c++;
    if (centreRoomsDone) c++;
    if (centreStaffDone) c++;
    if (centreEquipmentDone) c++;
    return c;
  }

  double get centreCompletionPercentage => centreCompletedStepsCount / 6.0;

  bool get canSubmitCentreForReview =>
      centreEntityDone && centreDocsDone && centreBankDone && centreRoomsDone;

  // Calculate Nurse Steps
  bool get nurseProfileDone => true; // Finished at initial 3-step signup
  bool get nurseDocsDone => _nurseDocUploaded(nurseHprDocId) && _nurseDocUploaded(nurseDegreeDocId);
  bool get nurseMedicalFitnessComplete => _nurseDocUploaded(nurseMedicalDocId);
  bool get nurseBankDone => bankAccount.isConfigured;
  bool get nurseSkillsDone => nurseSkills.isNotEmpty;
  bool get nursePoliceDone => nursePoliceConsentDone;

  int get nurseCompletedStepsCount {
    int c = 0;
    if (nurseProfileDone) c++;
    if (nurseDocsDone) c++;
    if (nurseMedicalFitnessComplete) c++;
    if (nurseBankDone) c++;
    if (nurseSkillsDone) c++;
    if (nursePoliceDone) c++;
    return c;
  }

  double get nurseCompletionPercentage => nurseCompletedStepsCount / 6.0;

  bool get canSubmitNurseForReview =>
      nurseProfileDone && nurseDocsDone && nurseBankDone && nurseSkillsDone;

  PartnerOnboardingState copyWith({
    BankAccountInfo? bankAccount,
    List<Room>? rooms,
    List<StaffMember>? staffMembers,
    List<EquipmentItem>? equipmentList,
    List<ComplianceDocItem>? centreComplianceDocs,
    List<ComplianceDocItem>? nurseDocs,
    List<String>? nurseSkills,
    double? nurseHourlyRate,
    double? nurseDailyRate,
    bool? nursePoliceConsentDone,
  }) {
    return PartnerOnboardingState(
      bankAccount: bankAccount ?? this.bankAccount,
      rooms: rooms ?? this.rooms,
      staffMembers: staffMembers ?? this.staffMembers,
      equipmentList: equipmentList ?? this.equipmentList,
      centreComplianceDocs: centreComplianceDocs ?? this.centreComplianceDocs,
      nurseDocs: nurseDocs ?? this.nurseDocs,
      nurseSkills: nurseSkills ?? this.nurseSkills,
      nurseHourlyRate: nurseHourlyRate ?? this.nurseHourlyRate,
      nurseDailyRate: nurseDailyRate ?? this.nurseDailyRate,
      nursePoliceConsentDone: nursePoliceConsentDone ?? this.nursePoliceConsentDone,
    );
  }
}

final partnerOnboardingProvider =
    StateNotifierProvider<PartnerOnboardingNotifier, PartnerOnboardingState>(
  (ref) => PartnerOnboardingNotifier(ref),
);

class PartnerOnboardingNotifier extends StateNotifier<PartnerOnboardingState> {
  final Ref ref;

  /// Everything partner-entered (rooms, staff, equipment, documents, bank,
  /// skills) starts empty / not uploaded — the partner adds it.
  PartnerOnboardingNotifier(this.ref) : super(PartnerOnboardingState.initial);

  void setNurseSkills(List<String> skills) {
    state = state.copyWith(nurseSkills: List.unmodifiable(skills));
  }

  void setNurseDailyRate(double rate) {
    state = state.copyWith(nurseDailyRate: rate);
  }

  void setNursePoliceConsent(bool consented) {
    state = state.copyWith(nursePoliceConsentDone: consented);
  }

  // Bank update
  void updateBankAccount(BankAccountInfo bank) {
    state = state.copyWith(bankAccount: bank);
  }

  // Room additions & edits
  void addRoom(Room room) {
    state = state.copyWith(rooms: [...state.rooms, room]);
  }

  void removeRoom(String roomId) {
    state = state.copyWith(
      rooms: state.rooms.where((r) => r.id != roomId).toList(),
    );
  }

  void toggleBedStatus(String roomId, String bedId) {
    final updatedRooms = state.rooms.map((room) {
      if (room.id != roomId) return room;
      final updatedBeds = room.beds.map((bed) {
        if (bed.id != bedId) return bed;
        return BedSlot(id: bed.id, label: bed.label, occupied: !bed.occupied);
      }).toList();
      return Room(
        id: room.id,
        ward: room.ward,
        roomNumber: room.roomNumber,
        ratePerDay: room.ratePerDay,
        beds: updatedBeds,
      );
    }).toList();
    state = state.copyWith(rooms: updatedRooms);
  }

  // Staff additions & edits
  void addStaffMember(StaffMember staff) {
    state = state.copyWith(staffMembers: [...state.staffMembers, staff]);
  }

  void removeStaffMember(String staffId) {
    state = state.copyWith(
      staffMembers: state.staffMembers.where((s) => s.id != staffId).toList(),
    );
  }

  // Equipment additions & edits
  void addEquipmentItem(EquipmentItem item) {
    state = state.copyWith(equipmentList: [...state.equipmentList, item]);
  }

  void removeEquipmentItem(String itemId) {
    state = state.copyWith(
      equipmentList: state.equipmentList.where((e) => e.id != itemId).toList(),
    );
  }

  // Compliance doc upload simulation
  void markDocUploaded({required String docId, required bool isCentre, required String fileName}) {
    if (isCentre) {
      final updated = state.centreComplianceDocs.map((d) {
        if (d.id != docId) return d;
        return ComplianceDocItem(
          id: d.id,
          title: d.title,
          docType: d.docType,
          fileName: fileName,
          expiry: 'Uploaded just now',
          isUploaded: true,
          isVerified: false,
        );
      }).toList();
      state = state.copyWith(centreComplianceDocs: updated);
    } else {
      final updated = state.nurseDocs.map((d) {
        if (d.id != docId) return d;
        return ComplianceDocItem(
          id: d.id,
          title: d.title,
          docType: d.docType,
          fileName: fileName,
          expiry: 'Uploaded just now',
          isUploaded: true,
          isVerified: false,
        );
      }).toList();
      state = state.copyWith(nurseDocs: updated);
    }
  }

  // Submit Centre for review — ALLCURO schedules the site visit afterwards.
  Future<void> submitCentreForReview() async {
    await ref
        .read(authViewModelProvider.notifier)
        .setCentreVerificationStatus(CentreVerificationStatus.pendingReview);
  }

  // Submit Nurse for review
  Future<void> submitNurseForReview() async {
    await ref
        .read(authViewModelProvider.notifier)
        .setPractitionerVerificationStatus(NurseVerificationStatus.underReview);
  }
}

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
    this.bankName = 'HDFC Bank',
    this.accountNumber = '50100482910482',
    this.ifscCode = 'HDFC0001234',
    this.accountHolderName = 'Sanjeevani Elder Care LLP',
    this.accountType = 'Current Account',
    this.panNumber = 'AAECS1234F',
    this.isVerified = true,
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

  const ComplianceDocItem({
    required this.id,
    required this.title,
    required this.docType,
    required this.fileName,
    required this.expiry,
    this.isUploaded = true,
    this.isVerified = true,
  });
}

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
  final bool nurseMedicalFitnessDone;
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
    required this.nurseMedicalFitnessDone,
    required this.nursePoliceConsentDone,
  });

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
  bool get nurseDocsDone => nurseDocs.where((d) => d.isUploaded).length >= 2;
  bool get nurseMedicalFitnessComplete => nurseMedicalFitnessDone;
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
    bool? nurseMedicalFitnessDone,
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
      nurseMedicalFitnessDone: nurseMedicalFitnessDone ?? this.nurseMedicalFitnessDone,
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

  PartnerOnboardingNotifier(this.ref)
      : super(
          PartnerOnboardingState(
            bankAccount: const BankAccountInfo(),
            rooms: const [
              Room(
                id: 'r-101',
                ward: 'Care Wing A',
                roomNumber: 'Room 101 · Semi-Private',
                ratePerDay: '₹2,200/day',
                beds: [
                  BedSlot(id: 'b-101-1', label: 'Bed 101-A', occupied: true),
                  BedSlot(id: 'b-101-2', label: 'Bed 101-B', occupied: false),
                ],
              ),
              Room(
                id: 'r-102',
                ward: 'Care Wing A',
                roomNumber: 'Room 102 · Deluxe Single Suite',
                ratePerDay: '₹3,500/day',
                beds: [
                  BedSlot(id: 'b-102-1', label: 'Bed 102-A', occupied: false),
                ],
              ),
              Room(
                id: 'r-icu-1',
                ward: 'ICU & High Dependency',
                roomNumber: 'ICU Unit 01',
                ratePerDay: '₹4,800/day',
                beds: [
                  BedSlot(id: 'b-icu-1', label: 'ICU Bed 1', occupied: true),
                  BedSlot(id: 'b-icu-2', label: 'ICU Bed 2', occupied: false),
                ],
              ),
            ],
            staffMembers: const [
              StaffMember(
                id: 's-1',
                name: 'Rekha Menon',
                roleType: StaffRoleType.gnmNurse,
                qualification: 'GNM · 5 yrs exp',
                experienceYears: 5,
                ratio: '1:4',
                shiftRate: 1800.0,
              ),
              StaffMember(
                id: 's-2',
                name: 'Joseph Thomas',
                roleType: StaffRoleType.bscNursing,
                qualification: 'B.Sc Nursing · 8 yrs exp',
                experienceYears: 8,
                ratio: '1:2',
                shiftRate: 2400.0,
              ),
              StaffMember(
                id: 's-3',
                name: 'Farida Sheikh',
                roleType: StaffRoleType.careAttendant,
                qualification: 'Certified Attendant · 3 yrs exp',
                experienceYears: 3,
                ratio: '1:4',
                shiftRate: 1200.0,
                certificateExpiring: true,
              ),
            ],
            equipmentList: const [
              EquipmentItem(
                id: 'eq-1',
                title: 'Philips EverFlo 5L Oxygen Concentrator',
                category: EquipmentCategory.respiratory,
                condition: EquipmentCondition.brandNew,
                dailyRate: 250.0,
                monthlyRate: 4500.0,
                depositAmount: 5000.0,
                stockQuantity: 6,
                specifications: '0.5 to 5 LPM continuous oxygen, 93% ± 3% purity, quiet operation.',
              ),
              EquipmentItem(
                id: 'eq-2',
                title: 'Motorized 5-Function ICU Hospital Bed with Mattress',
                category: EquipmentCategory.hospitalBeds,
                condition: EquipmentCondition.brandNew,
                dailyRate: 350.0,
                monthlyRate: 6500.0,
                depositAmount: 8000.0,
                stockQuantity: 4,
                specifications: 'Remote-controlled backrest, leg elevation, Trendelenburg, and height adjust.',
              ),
              EquipmentItem(
                id: 'eq-3',
                title: 'ResMed AirSense 10 AutoSet BiPAP/CPAP Machine',
                category: EquipmentCategory.respiratory,
                condition: EquipmentCondition.refurbishedGradeA,
                dailyRate: 300.0,
                monthlyRate: 5500.0,
                depositAmount: 6000.0,
                stockQuantity: 3,
                specifications: 'Auto-adjusting pressure, integrated heated humidifier, cellular connectivity.',
              ),
              EquipmentItem(
                id: 'eq-4',
                title: 'Karma Champion Deluxe Folding Wheelchair',
                category: EquipmentCategory.mobility,
                condition: EquipmentCondition.brandNew,
                dailyRate: 100.0,
                monthlyRate: 1800.0,
                depositAmount: 2000.0,
                stockQuantity: 8,
                specifications: 'Lightweight aluminum frame, ergonomic armrests, puncture-proof wheels.',
              ),
            ],
            centreComplianceDocs: const [
              ComplianceDocItem(
                id: 'cd-1',
                title: 'Clinical Establishment Act Licence (CEA)',
                docType: 'cea_license',
                fileName: 'karnataka_cea_reg_2026.pdf',
                expiry: 'Expires 14 Mar 2027',
                isUploaded: true,
                isVerified: true,
              ),
              ComplianceDocItem(
                id: 'cd-2',
                title: 'Fire Safety NOC Certificate',
                docType: 'fire_noc',
                fileName: 'fire_safety_clearance.pdf',
                expiry: 'Valid till 30 Nov 2026',
                isUploaded: true,
                isVerified: true,
              ),
              ComplianceDocItem(
                id: 'cd-3',
                title: 'Biomedical Waste Authorisation',
                docType: 'biowaste_noc',
                fileName: 'kspcb_biowaste_mou.pdf',
                expiry: 'Valid till 18 Jan 2027',
                isUploaded: true,
                isVerified: true,
              ),
              ComplianceDocItem(
                id: 'cd-4',
                title: 'Building & Ward Inspection Photos',
                docType: 'facility_photos',
                fileName: 'facility_photos_batch_6.zip',
                expiry: 'Uploaded 16 Aug 2026',
                isUploaded: true,
                isVerified: true,
              ),
            ],
            nurseDocs: const [
              ComplianceDocItem(
                id: 'nd-1',
                title: 'Government Identity Proof (Aadhaar / Passport)',
                docType: 'govt_id',
                fileName: 'aadhaar_card.pdf',
                expiry: 'Verified via UIDAI',
                isUploaded: true,
                isVerified: true,
              ),
              ComplianceDocItem(
                id: 'nd-2',
                title: 'Nursing Council Registration Certificate',
                docType: 'nursing_council',
                fileName: 'nursing_council_reg.pdf',
                expiry: 'Expires 02 Sep 2027',
                isUploaded: true,
                isVerified: true,
              ),
              ComplianceDocItem(
                id: 'nd-hpr',
                title: 'Healthcare Professionals Registry (HPR / ABHA ID)',
                docType: 'hpr_registry',
                fileName: 'hpr_council_enrollment.pdf',
                expiry: 'ABHA-HPR: 91-4820-9921-1209 (Verified)',
                isUploaded: true,
                isVerified: true,
              ),
              ComplianceDocItem(
                id: 'nd-3',
                title: 'Nursing Degree / GNM Diploma Certificate',
                docType: 'degree_certificate',
                fileName: 'gnm_diploma_certificate.pdf',
                expiry: 'Verified',
                isUploaded: true,
                isVerified: true,
              ),
            ],
            nurseSkills: const [
              'Post-Surgical Care',
              'ICU & Tracheostomy Care',
              'IV Infusion & Injections',
              'Wound & Bed Sore Dressing',
              'Elderly Mobility & Vitals',
            ],
            nurseHourlyRate: 250.0,
            nurseDailyRate: 2200.0,
            nurseMedicalFitnessDone: true,
            nursePoliceConsentDone: true,
          ),
        );

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

  // Submit Centre for review & schedule site visit
  Future<void> submitCentreForReview() async {
    await ref
        .read(authViewModelProvider.notifier)
        .setCentreVerificationStatus(CentreVerificationStatus.siteVisitScheduled);
  }

  // Submit Nurse for review
  Future<void> submitNurseForReview() async {
    await ref
        .read(authViewModelProvider.notifier)
        .setPractitionerVerificationStatus(NurseVerificationStatus.underReview);
  }
}

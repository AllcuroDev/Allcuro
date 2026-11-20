import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/partner_remote.dart';
import '../../../core/provider_role.dart';
import '../../../core/ui/pick_photo.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../clinician/presentation/signup/clinician_signup_view_model.dart';
import '../data/identity_service.dart';
import '../data/verified_identity.dart';

final identityServiceProvider = Provider<IdentityService>((ref) => IdentityService());

/// Document ids for the Aadhaar card photos in `partners.details.documents`.
const aadhaarFrontDocId = 'aadhaar_front';
const aadhaarBackDocId = 'aadhaar_back';

/// Everything the two verification steps collect, mutated in place by the
/// step widgets (same pattern as the sign-up wizards' data classes).
class IdentityFormData {
  /// Doctors: full name as on the NMC register. Nurses only type it when the
  /// register is down (NRTS returns the name otherwise).
  String registeredName = '';

  /// NUID for nurses, NMC / state council registration number for doctors.
  String registrationNumber = '';

  /// Doctors, optional filters for the NMC search.
  MedicalCouncil? council;
  int? year;

  RegistryRecord? registry;

  /// Set when the last check failed because the government site was down —
  /// the partner may then continue and ALLCURO verifies by hand.
  bool portalDown = false;

  /// Digits only, no spaces.
  String aadhaar = '';
  bool aadhaarConsent = false;
  PickedPhoto? aadhaarFront;
  PickedPhoto? aadhaarBack;
}

class IdentityVerificationState {
  final int stepIndex;
  final IdentityFormData data;
  final bool isBusy;
  final String? error;

  /// Doctors: State Medical Councils and registration years for the pickers
  /// (empty until loaded, or if loading failed — both are optional filters).
  final List<MedicalCouncil> councils;
  final List<int> years;

  const IdentityVerificationState({
    required this.stepIndex,
    required this.data,
    this.isBusy = false,
    this.error,
    this.councils = const [],
    this.years = const [],
  });

  IdentityVerificationState copyWith({
    int? stepIndex,
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<MedicalCouncil>? councils,
    List<int>? years,
  }) {
    return IdentityVerificationState(
      stepIndex: stepIndex ?? this.stepIndex,
      data: data,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      councils: councils ?? this.councils,
      years: years ?? this.years,
    );
  }
}

final identityVerificationViewModelProvider =
    NotifierProvider.autoDispose<IdentityVerificationViewModel, IdentityVerificationState>(
      IdentityVerificationViewModel.new,
    );

/// Drives `IdentityVerificationScreen`:
///  1) registration — NUID checked against INC NRTS for nurses; name +
///     registration number checked against the NMC register for doctors;
///  2) Aadhaar KYC — Aadhaar number + photo of the card, uploaded to the
///     private `kyc-documents` bucket for ALLCURO to review.
/// On success the partner's row in `public.partners` is created with the
/// register's details, the [VerifiedIdentity] is saved to the session, and
/// the router moves on to the sign-up wizard.
class IdentityVerificationViewModel extends AutoDisposeNotifier<IdentityVerificationState> {
  static const stepCount = 2;

  IdentityService get _service => ref.read(identityServiceProvider);

  ProviderRole? get _role => ref.read(authViewModelProvider).valueOrNull?.role;

  bool get isDoctor => _role == ProviderRole.clinician;

  bool _disposed = false;

  @override
  IdentityVerificationState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final initial = IdentityVerificationState(stepIndex: 0, data: IdentityFormData());
    if (isDoctor) Future.microtask(_loadDoctorOptions);
    return initial;
  }

  Future<void> _loadDoctorOptions() async {
    try {
      final councils = await _service.doctorCouncils();
      final years = await _service.doctorYears();
      if (!_disposed) state = state.copyWith(councils: councils, years: years);
    } catch (_) {
      // Optional filters — the check works without them.
    }
  }

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

  void setAadhaarPhoto({required bool front, required PickedPhoto photo}) {
    if (front) {
      state.data.aadhaarFront = photo;
    } else {
      state.data.aadhaarBack = photo;
    }
    touch();
  }

  /// Whether the registration step has what the check needs.
  bool get registrationReady {
    final d = state.data;
    final number = d.registrationNumber.trim();
    if (isDoctor) return d.registeredName.trim().length >= 2 && number.isNotEmpty;
    return number.length >= 3;
  }

  Future<void> verifyRegistration() async {
    final d = state.data;
    await _run(() async {
      d.portalDown = false;
      try {
        d.registry = isDoctor
            ? await _service.verifyDoctor(
                name: d.registeredName,
                regNo: d.registrationNumber,
                council: d.council,
                year: d.year,
              )
            : await _service.verifyNuid(d.registrationNumber);
      } on VerificationException catch (e) {
        d.portalDown = e.portalDown;
        rethrow;
      }
    });
  }

  /// Register unreachable: continue with what the partner typed; ALLCURO
  /// checks it during review.
  void continueWithoutCheck() {
    final d = state.data;
    if (!isDoctor && d.registeredName.trim().length < 2) {
      state = state.copyWith(error: 'Enter your full name as registered with the nursing council to continue.');
      return;
    }
    d.registry = _service.manualRecord(
      isDoctor: isDoctor,
      name: d.registeredName,
      regNo: d.registrationNumber,
      council: d.council,
      year: d.year,
    );
    d.portalDown = false;
    state = state.copyWith(stepIndex: 1, clearError: true);
  }

  bool get kycReady {
    final d = state.data;
    return d.aadhaar.length == 12 && d.aadhaarFront != null && d.aadhaarConsent;
  }

  /// Uploads the Aadhaar photos, creates / updates the partner row and saves
  /// the identity; the router redirect takes it from there.
  Future<void> completeKyc() async {
    final d = state.data;
    final registry = d.registry;
    final role = _role;
    if (registry == null || role == null) return;
    if (!IdentityService.isValidAadhaar(d.aadhaar)) {
      state = state.copyWith(error: 'That is not a valid Aadhaar number. Check the 12 digits on your card.');
      return;
    }

    await _run(() async {
      final docs = <String, dynamic>{};
      for (final (id, photo) in [(aadhaarFrontDocId, d.aadhaarFront), (aadhaarBackDocId, d.aadhaarBack)]) {
        if (photo == null) continue;
        final doc = await PartnerRemote.uploadDocument(
          role: role,
          docId: id,
          bytes: photo.bytes,
          fileName: photo.fileName,
        );
        docs[id] = doc.toJson();
      }

      final number = d.registrationNumber.trim().toUpperCase();
      final name = registry.registeredName.isNotEmpty ? registry.registeredName : d.registeredName.trim();
      final identity = VerifiedIdentity(
        fullName: name,
        dob: registry.dob,
        address: registry.address,
        aadhaarLast4: d.aadhaar.substring(8),
        registrationLabel: isDoctor ? 'Medical Reg. No.' : 'NUID',
        registrationNumber: number,
        council: registry.council,
        qualification: registry.qualification,
        profession: isDoctor ? ClinicianProfession.doctor.name : null,
        registry: registry.toJson(),
      );

      // Only the last 4 Aadhaar digits are stored; ALLCURO matches them to the card photo.
      await PartnerRemote.save(
        role,
        fields: {
          'display_name': name,
          'qualification': registry.qualification,
          'headline': registry.qualification,
          'registration_number': number,
          'council': registry.council,
          if (registry.address.isNotEmpty) 'address': registry.address,
          'identity': identity.toJson(),
        },
        details: {
          'documents': docs,
          'kyc': {
            'aadhaarLast4': identity.aadhaarLast4,
            'consentAt': DateTime.now().toUtc().toIso8601String(),
            'registryAutoVerified': registry.autoVerified,
          },
        },
      );

      await ref.read(authViewModelProvider.notifier).saveIdentity(identity);
      if (ref.read(authViewModelProvider).hasError) {
        throw StateError('Could not save your verification. Please try again.');
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await action();
      // On a completed KYC the router replaces this screen and disposes this notifier.
      if (!_disposed) state = state.copyWith(isBusy: false);
    } on Object catch (e) {
      if (_disposed) return;
      state = state.copyWith(isBusy: false, error: e is StateError ? e.message : e.toString());
    }
  }
}

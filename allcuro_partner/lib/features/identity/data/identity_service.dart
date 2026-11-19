import '../../auth/data/auth_service.dart';
import 'verified_identity.dart';

/// Local mock of the registry and Aadhaar e-KYC lookups. Nothing leaves the
/// device: each call validates the input's format, waits briefly, and echoes
/// back what the partner entered (their registered name) — it never invents
/// a person. Date of birth, gender and address aren't returned, so the
/// sign-up wizard asks for them. Swap the bodies for the real verification
/// partner's API (NRTS / NMC-IMR lookup, UIDAI-licensed e-KYC via a KUA)
/// once there's a backend — callers only depend on the return types.
class IdentityService {
  /// The only Aadhaar OTP [verifyAadhaarOtp] accepts — shown on the OTP
  /// field so the mock flow is usable.
  static const demoOtp = '123456';

  static final _registrationPattern = RegExp(r'^[A-Za-z0-9/\-]{4,20}$');

  Future<RegistryRecord> verifyNuid(String nuid, {required String registeredName}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!RegExp(r'^[A-Za-z0-9]{6,20}$').hasMatch(nuid.trim())) {
      throw const AuthException('Enter the NUID exactly as shown on your NRTS registration.');
    }
    return RegistryRecord(
      registeredName: _requireName(registeredName),
      council: 'Karnataka State Nursing Council',
      qualification: 'GNM',
    );
  }

  static String _requireName(String name) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) {
      throw const AuthException('Enter your full name exactly as registered.');
    }
    return clean;
  }

  Future<RegistryRecord> verifyCouncilRegistration({
    required bool isPhysiotherapist,
    required String registrationNumber,
    required String council,
    required String registeredName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!_registrationPattern.hasMatch(registrationNumber.trim())) {
      throw const AuthException('Enter a valid registration number (letters, digits, / or -).');
    }
    return RegistryRecord(
      registeredName: _requireName(registeredName),
      council: council,
      qualification: isPhysiotherapist ? 'BPT' : 'MBBS',
    );
  }

  Future<void> sendAadhaarOtp(String aadhaar) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Aadhaar numbers are 12 digits and never start with 0 or 1.
    if (!RegExp(r'^[2-9]\d{11}$').hasMatch(aadhaar)) {
      throw const AuthException('Enter a valid 12-digit Aadhaar number.');
    }
  }

  /// [registeredName] is the name from the registry step — the mock returns
  /// it as the Aadhaar name (a real e-KYC returns the name on Aadhaar, which
  /// the caller then matches against the registry).
  Future<AadhaarProfile> verifyAadhaarOtp({
    required String aadhaar,
    required String otp,
    required String registeredName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp != demoOtp) {
      throw const AuthException('Incorrect OTP. Please try again.');
    }
    return AadhaarProfile(name: registeredName);
  }
}

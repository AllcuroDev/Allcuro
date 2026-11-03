import '../../auth/data/auth_service.dart';
import 'verified_identity.dart';

/// Local mock of the registry and Aadhaar e-KYC lookups. Nothing leaves the
/// device: each call validates the input's format, waits briefly, and
/// returns fixed demo records. Swap the bodies for the real verification
/// partner's API (NRTS / NMC-IMR lookup, UIDAI-licensed e-KYC via a KUA)
/// once there's a backend — callers only depend on the return types.
class IdentityService {
  /// The only Aadhaar OTP [verifyAadhaarOtp] accepts — shown on the OTP
  /// field so the mock flow is usable.
  static const demoOtp = '123456';

  static final _registrationPattern = RegExp(r'^[A-Za-z0-9/\-]{4,20}$');

  Future<RegistryRecord> verifyNuid(String nuid) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!RegExp(r'^[A-Za-z0-9]{6,20}$').hasMatch(nuid.trim())) {
      throw const AuthException('Enter the NUID exactly as shown on your NRTS registration.');
    }
    return const RegistryRecord(
      registeredName: 'Priya Sharma',
      council: 'Karnataka State Nursing Council',
      qualification: 'GNM',
      registeredSince: 2017,
    );
  }

  Future<RegistryRecord> verifyCouncilRegistration({
    required bool isPhysiotherapist,
    required String registrationNumber,
    required String council,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!_registrationPattern.hasMatch(registrationNumber.trim())) {
      throw const AuthException('Enter a valid registration number (letters, digits, / or -).');
    }
    return RegistryRecord(
      registeredName: 'Arjun Rao',
      council: council,
      qualification: isPhysiotherapist ? 'BPT' : 'MBBS',
      registeredSince: 2013,
    );
  }

  Future<void> sendAadhaarOtp(String aadhaar) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Aadhaar numbers are 12 digits and never start with 0 or 1.
    if (!RegExp(r'^[2-9]\d{11}$').hasMatch(aadhaar)) {
      throw const AuthException('Enter a valid 12-digit Aadhaar number.');
    }
  }

  Future<AadhaarProfile> verifyAadhaarOtp({
    required String aadhaar,
    required String otp,
    required bool isClinician,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp != demoOtp) {
      throw const AuthException('Incorrect OTP. Please try again.');
    }
    return isClinician
        ? AadhaarProfile(
            name: 'Arjun Rao',
            dob: DateTime(1988, 11, 2),
            gender: 'Male',
            address: '221, 27th Main, HSR Layout Sector 2, Bengaluru, Karnataka 560102',
          )
        : AadhaarProfile(
            name: 'Priya Sharma',
            dob: DateTime(1996, 5, 14),
            gender: 'Female',
            address: '12, 4th Cross, Indiranagar, Bengaluru, Karnataka 560038',
          );
  }
}

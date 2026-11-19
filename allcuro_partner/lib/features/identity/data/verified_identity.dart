/// What a practitioner's professional register (INC NRTS for nurses, NMC /
/// state council for doctors & physiotherapists) returned for the number
/// they entered.
class RegistryRecord {
  final String registeredName;
  final String council;
  final String qualification;

  /// Year of first registration, when the register reports it.
  final int? registeredSince;

  const RegistryRecord({
    required this.registeredName,
    required this.council,
    required this.qualification,
    this.registeredSince,
  });
}

/// Demographic details returned by Aadhaar e-KYC after a successful OTP.
/// [dob], [gender] and [address] are null / empty when the e-KYC source
/// didn't provide them (e.g. the local mock) — the sign-up wizard then asks
/// the partner for them instead of locking them.
class AadhaarProfile {
  final String name;
  final DateTime? dob;
  final String? gender;
  final String address;

  const AadhaarProfile({required this.name, this.dob, this.gender, this.address = ''});
}

/// The identity a nurse / doctor / physiotherapist proved at sign-up —
/// registration (NUID or council reg. no.) plus Aadhaar e-KYC. Everything in
/// here is read-only for the rest of onboarding: the sign-up wizards prefill
/// from it and lock these fields.
class VerifiedIdentity {
  final String fullName;

  /// Null / empty when e-KYC didn't return them — then they're entered (and
  /// editable) in the sign-up wizard rather than locked.
  final DateTime? dob;
  final String? gender;
  final String address;
  final String aadhaarLast4;

  /// e.g. "NUID", "Medical Reg. No." — how [registrationNumber] is labelled.
  final String registrationLabel;
  final String registrationNumber;
  final String council;
  final String qualification;

  /// `ClinicianProfession.name` for doctors / physiotherapists; null for nurses.
  final String? profession;

  const VerifiedIdentity({
    required this.fullName,
    this.dob,
    this.gender,
    this.address = '',
    required this.aadhaarLast4,
    required this.registrationLabel,
    required this.registrationNumber,
    required this.council,
    required this.qualification,
    this.profession,
  });

  String get maskedAadhaar => 'XXXX XXXX $aadhaarLast4';

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'dob': dob?.toIso8601String(),
    'gender': gender,
    'address': address,
    'aadhaarLast4': aadhaarLast4,
    'registrationLabel': registrationLabel,
    'registrationNumber': registrationNumber,
    'council': council,
    'qualification': qualification,
    'profession': profession,
  };

  factory VerifiedIdentity.fromJson(Map<String, dynamic> json) => VerifiedIdentity(
    fullName: json['fullName'] as String,
    dob: DateTime.tryParse(json['dob'] as String? ?? ''),
    gender: json['gender'] as String?,
    address: json['address'] as String? ?? '',
    aadhaarLast4: json['aadhaarLast4'] as String,
    registrationLabel: json['registrationLabel'] as String,
    registrationNumber: json['registrationNumber'] as String,
    council: json['council'] as String,
    qualification: json['qualification'] as String,
    profession: json['profession'] as String?,
  );
}

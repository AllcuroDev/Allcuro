/// What a practitioner's professional register (INC NRTS for nurses, the NMC
/// Indian Medical Register for doctors) returned for the number they entered.
class RegistryRecord {
  final String registeredName;
  final String council;
  final String qualification;

  /// Year of first registration, when the register reports it.
  final int? registeredSince;

  /// Doctors only: the NMC record's date of birth and permanent address.
  final DateTime? dob;
  final String address;

  /// "INC NRTS" or "NMC IMR".
  final String source;

  /// False when the register was down and the partner continued anyway —
  /// ALLCURO then checks the registration by hand before approving.
  final bool autoVerified;

  /// Everything the register returned worth showing, in display order —
  /// shown to the partner after the check and to the admin during review.
  final List<(String, String)> fields;

  /// Official verification link (NRTS), when the register gives one.
  final String? verifyUrl;

  const RegistryRecord({
    required this.registeredName,
    required this.council,
    required this.qualification,
    this.registeredSince,
    this.dob,
    this.address = '',
    required this.source,
    this.autoVerified = true,
    this.fields = const [],
    this.verifyUrl,
  });

  /// Stored in `partners.identity.registry` for the admin's review panel.
  Map<String, dynamic> toJson() => {
    'source': source,
    'autoVerified': autoVerified,
    'checkedAt': DateTime.now().toUtc().toIso8601String(),
    'registeredName': registeredName,
    'council': council,
    'qualification': qualification,
    'registeredSince': registeredSince,
    'fields': [for (final (label, value) in fields) {'label': label, 'value': value}],
    'verifyUrl': verifyUrl,
  };
}

/// The identity a nurse / doctor proved at sign-up — registration (NUID or
/// NMC reg. no.) checked against the council register, plus Aadhaar KYC
/// (number + card photo, reviewed by ALLCURO). Everything in here is
/// read-only for the rest of onboarding: the sign-up wizards prefill from it
/// and lock these fields.
class VerifiedIdentity {
  final String fullName;

  /// Null / empty when the register didn't return them — then they're
  /// entered (and editable) in the sign-up wizard rather than locked.
  final DateTime? dob;
  final String? gender;
  final String address;
  final String aadhaarLast4;

  /// e.g. "NUID", "Medical Reg. No." — how [registrationNumber] is labelled.
  final String registrationLabel;
  final String registrationNumber;
  final String council;
  final String qualification;

  /// `ClinicianProfession.name` for doctors; null for nurses.
  final String? profession;

  /// The register's answer ([RegistryRecord.toJson]), kept for the admin.
  final Map<String, dynamic>? registry;

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
    this.registry,
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
    'registry': registry,
  };

  factory VerifiedIdentity.fromJson(Map<String, dynamic> json) => VerifiedIdentity(
    fullName: json['fullName'] as String,
    dob: DateTime.tryParse(json['dob'] as String? ?? ''),
    gender: json['gender'] as String?,
    address: json['address'] as String? ?? '',
    aadhaarLast4: json['aadhaarLast4'] as String,
    registrationLabel: json['registrationLabel'] as String,
    registrationNumber: json['registrationNumber'] as String? ?? '',
    council: json['council'] as String? ?? '',
    qualification: json['qualification'] as String? ?? '',
    profession: json['profession'] as String?,
    registry: json['registry'] is Map<String, dynamic> ? json['registry'] as Map<String, dynamic> : null,
  );
}

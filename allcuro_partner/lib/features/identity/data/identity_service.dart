import '../../../core/network/verification_api.dart';
import 'verified_identity.dart';

export '../../../core/network/verification_api.dart' show MedicalCouncil, VerificationException;

/// Registration checks for the identity step, through the `nuid` / `doctor`
/// Supabase Edge Functions (INC NRTS and the NMC Indian Medical Register),
/// plus Aadhaar number validation. The Aadhaar card photo is reviewed by
/// ALLCURO — there is no UIDAI e-KYC integration.
class IdentityService {
  /// Nurse: looks the NUID up in NRTS. Only an `Active` record passes.
  Future<RegistryRecord> verifyNuid(String nuid) async {
    final r = await VerificationApi.nurse(nuid);
    final status = _s(r['status']);
    if (status.toLowerCase() != 'active') {
      throw VerificationException(
        'Your NUID is marked "${status.isEmpty ? 'inactive' : status}" by the Indian Nursing Council. '
        'Only active registrations can join ALLCURO.',
      );
    }
    final name = titleCaseName(_s(r['name']));
    final council = _s(r['council']);
    final registeredAs = _s(r['registeredAs']);
    return RegistryRecord(
      registeredName: name,
      council: council.isEmpty ? 'Indian Nursing Council' : council,
      qualification: registeredAs,
      source: 'INC NRTS',
      verifyUrl: _s(r['verifyUrl']).isEmpty ? null : _s(r['verifyUrl']),
      fields: _rows([
        ('Name', name),
        ('NUID', _s(r['nuid'])),
        ('Status', status),
        ('Council', council),
        ('Registered as', registeredAs),
        ('Registration no.', _s(r['registrationNumber'])),
        ('Designation', _s(r['designation'])),
        ('Current employment', _s(r['currentEmployment'])),
        ('Institute', _s(r['institute'])),
        ('Sector', _s(r['sector'])),
      ]),
    );
  }

  /// Doctor: checks name + registration number (and optionally year / state
  /// council) against the NMC Indian Medical Register.
  Future<RegistryRecord> verifyDoctor({
    required String name,
    required String regNo,
    MedicalCouncil? council,
    int? year,
  }) async {
    if (name.trim().length < 2) {
      throw const VerificationException('Enter your full name as on your NMC registration.');
    }
    if (regNo.trim().isEmpty) {
      throw const VerificationException('Enter your medical registration number.');
    }
    final d = await VerificationApi.doctor(
      name: name,
      regNo: regNo,
      stateCode: council?.code,
      year: year?.toString(),
    );
    final regName = titleCaseName(_s(d['name']));
    final qualification = _s(d['qualification']);
    final councilName = _s(d['stateMedicalCouncil']);
    final extras = (d['additionalQualifications'] as List?)?.whereType<Map<String, dynamic>>() ?? const [];
    return RegistryRecord(
      registeredName: regName,
      council: councilName.isEmpty ? (council?.name ?? 'NMC') : councilName,
      qualification: qualification,
      registeredSince: int.tryParse('${d['yearOfInfo'] ?? ''}'),
      dob: _parseDmy(_s(d['dateOfBirth'])),
      address: _s(d['permanentAddress']),
      source: 'NMC IMR',
      fields: _rows([
        ('Name', regName),
        ('Registration no.', _s(d['registrationNumber'])),
        ('Registered on', _s(d['registrationDate'])),
        ('Medical council', councilName),
        ('Qualification', [qualification, _s(d['qualificationYear'])].where((s) => s.isNotEmpty).join(', ')),
        ('University', _s(d['university'])),
        for (final q in extras)
          ('Additional', [_s(q['qualification']), _s(q['year'])].where((s) => s.isNotEmpty).join(', ')),
        ("Father's / husband's name", _s(d['fatherOrHusbandName'])),
        ('Date of birth', _s(d['dateOfBirth']).split(' ').first),
      ]),
    );
  }

  /// Used when the register is down: records what the partner typed, marked
  /// as not auto-verified, so ALLCURO checks it by hand during review.
  RegistryRecord manualRecord({
    required bool isDoctor,
    required String name,
    required String regNo,
    MedicalCouncil? council,
    int? year,
  }) {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (isDoctor && cleanName.length < 2) {
      throw const VerificationException('Enter your full name as on your NMC registration.');
    }
    return RegistryRecord(
      registeredName: cleanName,
      council: isDoctor ? (council?.name ?? 'National Medical Commission') : 'Indian Nursing Council',
      qualification: '',
      registeredSince: year,
      source: isDoctor ? 'NMC IMR' : 'INC NRTS',
      autoVerified: false,
      fields: _rows([
        if (cleanName.isNotEmpty) ('Name (entered)', cleanName),
        (isDoctor ? 'Registration no.' : 'NUID', regNo.trim().toUpperCase()),
        if (council != null) ('Medical council', council.name),
        if (year != null) ('Year', '$year'),
        ('Check', 'Register unavailable — to be verified by ALLCURO'),
      ]),
    );
  }

  Future<List<MedicalCouncil>> doctorCouncils() => VerificationApi.doctorStates();

  Future<List<int>> doctorYears() => VerificationApi.doctorYears();

  /// Aadhaar numbers are 12 digits, never start with 0 or 1, and end in a
  /// Verhoeff check digit.
  static bool isValidAadhaar(String digits) => RegExp(r'^[2-9]\d{11}$').hasMatch(digits) && _verhoeff(digits);

  static String _s(Object? v) => v == null ? '' : '$v'.trim();

  static List<(String, String)> _rows(List<(String, String)> rows) =>
      rows.where((r) => r.$2.trim().isNotEmpty).toList();

  /// "21-08-1999 00:00" → DateTime(1999, 8, 21).
  static DateTime? _parseDmy(String s) {
    final m = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})').firstMatch(s);
    if (m == null) return null;
    final d = DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
    return d.year > 1900 && d.isBefore(DateTime.now()) ? d : null;
  }

  /// "SHARMA, YUKTI" → "Yukti Sharma"; "PRIYA  NAIR" → "Priya Nair".
  static String titleCaseName(String raw) {
    var s = raw.trim();
    final comma = s.indexOf(',');
    if (comma > 0) s = '${s.substring(comma + 1)} ${s.substring(0, comma)}';
    return s
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static const _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];
  static const _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  static bool _verhoeff(String digits) {
    var c = 0;
    final rev = digits.split('').reversed.map(int.parse).toList();
    for (var i = 0; i < rev.length; i++) {
      c = _d[c][_p[i % 8][rev[i]]];
    }
    return c == 0;
  }
}

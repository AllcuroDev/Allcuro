import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thrown by [VerificationApi] calls. [message] is shown to the partner as-is.
/// [portalDown] is true when the government register could not be reached
/// (HTTP 502) — that is *not* a failed verification, so callers let the
/// partner continue and ALLCURO checks the registration by hand.
class VerificationException implements Exception {
  final String message;
  final bool portalDown;

  const VerificationException(this.message, {this.portalDown = false});

  @override
  String toString() => message;
}

/// One State Medical Council from `GET /doctor/states`.
class MedicalCouncil {
  final String code;
  final String name;

  const MedicalCouncil(this.code, this.name);
}

/// Client for the `nuid` and `doctor` Supabase Edge Functions, which check
/// the Indian Nursing Council (NRTS) and NMC Indian Medical Register.
/// See `partner_verification_apis/API_USAGE.md`.
class VerificationApi {
  VerificationApi._();

  static FunctionsClient get _functions {
    final client = supabaseOrNull;
    if (client == null) {
      throw const VerificationException(
        'Registration checks need the app to be connected to ALLCURO (Supabase keys missing from this build).',
      );
    }
    return client.functions;
  }

  /// `GET /nuid/<nuid>` — the raw NRTS record on success (`found` true).
  /// Throws when the NUID is unknown; a revoked record is returned so the
  /// caller can explain it.
  static Future<Map<String, dynamic>> nurse(String nuid) async {
    final id = nuid.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{3,12}$').hasMatch(id)) {
      throw const VerificationException('Enter your NUID: 3–12 letters or digits, exactly as on your NRTS registration.');
    }
    final body = await _get('nuid/${Uri.encodeComponent(id)}', notFound: (_) {
      return 'No nurse registration was found for NUID $id. Check the number and try again.';
    });
    if (body['found'] != true) {
      throw VerificationException('No nurse registration was found for NUID $id. Check the number and try again.');
    }
    return body;
  }

  /// `GET /doctor?name=&regNo=&year=&state=` — the matched NMC record.
  static Future<Map<String, dynamic>> doctor({
    required String name,
    required String regNo,
    String? year,
    String? stateCode,
  }) async {
    final body = await _get(
      'doctor',
      query: {
        'name': name.trim(),
        'regNo': regNo.trim(),
        if (year != null && year.isNotEmpty) 'year': year,
        if (stateCode != null && stateCode.isNotEmpty) 'state': stateCode,
      },
      notFound: (b) => switch (b['reason']) {
        'name_mismatch' =>
          'This registration number exists, but under a different name. Enter your name exactly as on your NMC registration.',
        'removed' => 'The NMC register marks this registration as removed. Contact ALLCURO support if this is a mistake.',
        _ => 'No doctor was found with this registration number'
            '${stateCode != null || year != null ? ' for the council / year you picked' : ''}. Check the details and try again.',
      },
    );
    final doctor = body['doctor'];
    if (body['verified'] != true || doctor is! Map<String, dynamic>) {
      throw const VerificationException('Your registration could not be verified. Check the details and try again.');
    }
    return doctor;
  }

  /// State Medical Councils for the doctor form's dropdown.
  static Future<List<MedicalCouncil>> doctorStates() async {
    final body = await _get('doctor/states');
    final list = body['states'];
    if (list is! List) return const [];
    return [
      for (final s in list.whereType<Map<String, dynamic>>())
        MedicalCouncil('${s['code'] ?? ''}', '${s['name'] ?? ''}'),
    ];
  }

  /// Registration years for the doctor form's dropdown, newest first.
  static Future<List<int>> doctorYears() async {
    final body = await _get('doctor/years');
    final list = body['years'];
    if (list is! List) return const [];
    return list.whereType<num>().map((y) => y.toInt()).toList()..sort((a, b) => b.compareTo(a));
  }

  static Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
    String Function(Map<String, dynamic> body)? notFound,
  }) async {
    try {
      final res = await _functions.invoke(path, method: HttpMethod.get, queryParameters: query);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      throw const VerificationException('Unexpected response from the verification service. Please try again.');
    } on FunctionException catch (e) {
      final body = e.details is Map<String, dynamic> ? e.details as Map<String, dynamic> : <String, dynamic>{};
      switch (e.status) {
        case 404 when notFound != null:
          throw VerificationException(notFound(body));
        case 400:
          throw VerificationException('${body['error'] ?? 'Some details are missing or invalid.'}');
        case 502:
          throw const VerificationException(
            'The government register is not responding right now. Try again in a few minutes, '
            'or continue and ALLCURO will verify your registration manually.',
            portalDown: true,
          );
        case 0:
          throw const VerificationException('Could not reach the verification service. Check your connection and try again.');
        default:
          throw VerificationException('Verification failed (HTTP ${e.status}). Please try again.');
      }
    } on VerificationException {
      rethrow;
    } catch (_) {
      throw const VerificationException('Could not reach the verification service. Check your connection and try again.');
    }
  }
}

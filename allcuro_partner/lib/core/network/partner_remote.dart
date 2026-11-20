import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../provider_role.dart';
import 'phone_auth.dart';
import 'supabase_config.dart';

/// A KYC / onboarding file the partner uploaded. Same shape as the web
/// portal's `UploadedDoc`, kept in `partners.details.documents[docId]` so the
/// admin can open it from the private `kyc-documents` bucket.
class UploadedDoc {
  final String fileName;

  /// Object path in `kyc-documents`; null in demo builds (no Supabase).
  final String? path;
  final DateTime uploadedAt;

  const UploadedDoc({required this.fileName, required this.path, required this.uploadedAt});

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'path': path,
    'uploadedAt': uploadedAt.toUtc().toIso8601String(),
  };

  static UploadedDoc? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return UploadedDoc(
      fileName: '${json['fileName'] ?? 'File'}',
      path: json['path'] as String?,
      uploadedAt: DateTime.tryParse('${json['uploadedAt']}') ?? DateTime.now(),
    );
  }
}

class PartnerSaveException implements Exception {
  final String message;

  const PartnerSaveException(this.message);

  @override
  String toString() => message;
}

/// The signed-in partner's row in `public.partners` (one per role) — the
/// app's twin of `allcuro_web/src/partner/session.ts` `push()`. The row's
/// `status` is the truth for approval: partners can only move it up to
/// `under_review`; the `partners_guard` trigger keeps everything after that
/// (approve, reject, suspend, prices) for the admin.
class PartnerRemote {
  PartnerRemote._();

  static const _bucket = 'kyc-documents';

  /// Serialises writes so quick successive saves land in order.
  static Future<void> _chain = Future.value();

  static String dbRole(ProviderRole role) => role.name; // nurse | clinician | centre

  /// What customers browse by. Doctors are the only clinicians signing up for now.
  static String kindFor(ProviderRole role) => switch (role) {
    ProviderRole.nurse => 'nurse',
    ProviderRole.clinician => 'doctor',
    ProviderRole.centre => 'centre',
  };

  static String? get _userId => PhoneAuth.currentUserId;

  /// This user's row for [role], or null (none yet, offline, or demo build).
  static Future<Map<String, dynamic>?> fetch(ProviderRole role) async {
    final client = supabaseOrNull;
    final uid = _userId;
    if (client == null || uid == null) return null;
    try {
      return await client.from('partners').select().eq('user_id', uid).eq('role', dbRole(role)).maybeSingle();
    } catch (e) {
      debugPrint('[partners] fetch failed: $e');
      return null;
    }
  }

  /// Upserts [role]'s row with [fields] (column → value) and merges [details]
  /// into the `details` json (and `details.documents` one level deeper), so
  /// separate screens never overwrite each other's answers. Throws
  /// [PartnerSaveException] on failure; no-op in demo builds.
  static Future<void> save(
    ProviderRole role, {
    Map<String, dynamic> fields = const {},
    Map<String, dynamic> details = const {},
  }) {
    final run = _chain.then((_) => _save(role, fields, details));
    _chain = run.catchError((_) {});
    return run;
  }

  /// [save] for incidental edits (skills, bank…): failures are logged, not thrown.
  static Future<void> saveQuietly(
    ProviderRole role, {
    Map<String, dynamic> fields = const {},
    Map<String, dynamic> details = const {},
  }) async {
    try {
      await save(role, fields: fields, details: details);
    } catch (e) {
      debugPrint('[partners] save failed: $e');
    }
  }

  static Future<void> _save(ProviderRole role, Map<String, dynamic> fields, Map<String, dynamic> details) async {
    final client = supabaseOrNull;
    if (client == null) return;
    final uid = _userId;
    if (uid == null) throw const PartnerSaveException('Your session has expired. Please log in again.');
    try {
      final existing = await client
          .from('partners')
          .select('details')
          .eq('user_id', uid)
          .eq('role', dbRole(role))
          .maybeSingle();
      final current = Map<String, dynamic>.from((existing?['details'] as Map?) ?? const {});
      final merged = {...current, ...details};
      if (details['documents'] is Map) {
        merged['documents'] = {
          ...Map<String, dynamic>.from((current['documents'] as Map?) ?? const {}),
          ...Map<String, dynamic>.from(details['documents'] as Map),
        };
      }
      final phone = client.auth.currentUser?.phone ?? '';
      await client.from('partners').upsert({
        'user_id': uid,
        'role': dbRole(role),
        'kind': kindFor(role),
        if (phone.isNotEmpty) 'phone': phone.startsWith('+') ? phone : '+$phone',
        ...fields,
        'details': merged,
      }, onConflict: 'user_id,role');
    } on PostgrestException catch (e) {
      debugPrint('[partners] save failed: ${e.code} ${e.message}');
      throw PartnerSaveException('Could not save your profile: ${e.message}');
    } on PartnerSaveException {
      rethrow;
    } catch (e) {
      debugPrint('[partners] save failed: $e');
      throw const PartnerSaveException('Could not save your profile. Check your connection and try again.');
    }
  }

  /// Uploads a file to the private `kyc-documents` bucket under the user's
  /// own folder (as the storage policy requires). Records nothing on the row —
  /// pass the result to [save] under `details.documents`.
  static Future<UploadedDoc> uploadDocument({
    required ProviderRole role,
    required String docId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final client = supabaseOrNull;
    final now = DateTime.now();
    if (client == null) return UploadedDoc(fileName: fileName, path: null, uploadedAt: now);
    final uid = _userId;
    if (uid == null) throw const PartnerSaveException('Please log in again to upload documents.');
    final dot = fileName.lastIndexOf('.');
    final ext = dot > 0 ? fileName.substring(dot + 1).toLowerCase() : 'jpg';
    final path = '$uid/${dbRole(role)}/$docId-${now.millisecondsSinceEpoch}.$ext';
    try {
      await client.storage
          .from(_bucket)
          .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true, contentType: _contentType(ext)));
    } on StorageException catch (e) {
      throw PartnerSaveException('Upload failed: ${e.message}');
    } catch (_) {
      throw const PartnerSaveException('Upload failed. Check your connection and try again.');
    }
    return UploadedDoc(fileName: fileName, path: path, uploadedAt: now);
  }

  static String _contentType(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'pdf' => 'application/pdf',
    _ => 'image/jpeg',
  };
}

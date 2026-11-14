import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'supabase_config.dart';

/// Real phone sign-in through Supabase Auth (SMS OTP via the Twilio provider
/// configured in the Supabase dashboard). Mirrors `allcuro_web/src/lib/phoneAuth.ts`.
///
/// Without Supabase keys in the build ([SupabaseConfig.isConfigured] false)
/// the app falls back to demo mode, where [demoOtp] is the only valid code.
class PhoneAuth {
  PhoneAuth._();

  static const demoOtp = '123456';

  static bool get isDemo => !SupabaseConfig.isConfigured;

  /// "98765 43210" → "+919876543210" (India).
  static String toE164(String phone) {
    final digits = digitsOf(phone);
    return '+91${digits.length > 10 ? digits.substring(digits.length - 10) : digits}';
  }

  static String digitsOf(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  /// Id of the signed-in Supabase user, or null.
  static String? get currentUserId => supabaseOrNull?.auth.currentUser?.id;

  static bool get hasSession => supabaseOrNull?.auth.currentSession != null;

  /// Sends a 6-digit code by SMS. Creates the account on first use.
  static Future<void> requestOtp(String phone) async {
    if (digitsOf(phone).length != 10) {
      throw const PhoneAuthException('Enter a valid 10-digit mobile number.');
    }
    final client = supabaseOrNull;
    if (client == null) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return;
    }
    try {
      await client.auth.signInWithOtp(phone: toE164(phone));
    } on sb.AuthException catch (e) {
      throw PhoneAuthException(_friendly(e, verify: false));
    } catch (_) {
      throw const PhoneAuthException('Could not send the code. Check your connection and try again.');
    }
  }

  /// Checks the code and signs in. Returns the signed-in user's id (null in demo mode).
  static Future<String?> confirmOtp(String phone, String code) async {
    final token = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(token)) {
      throw const PhoneAuthException('Enter the 6-digit code we sent you.');
    }
    final client = supabaseOrNull;
    if (client == null) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (token != demoOtp) throw const PhoneAuthException('Incorrect code. Use demo code $demoOtp.');
      return null;
    }
    try {
      final res = await client.auth.verifyOTP(phone: toE164(phone), token: token, type: sb.OtpType.sms);
      final user = res.user;
      if (user == null) throw const PhoneAuthException('Could not sign in. Please try again.');
      return user.id;
    } on sb.AuthException catch (e) {
      throw PhoneAuthException(_friendly(e, verify: true));
    } on PhoneAuthException {
      rethrow;
    } catch (_) {
      throw const PhoneAuthException('Could not verify the code. Check your connection and try again.');
    }
  }

  static Future<void> signOut() async {
    try {
      await supabaseOrNull?.auth.signOut();
    } catch (_) {
      // Already signed out / offline — the local session is cleared either way.
    }
  }

  /// Readable message for a Supabase/Twilio error. Unrecognised errors are
  /// shown as-is (never hidden) and the raw error is logged for debugging.
  static String _friendly(sb.AuthException e, {required bool verify}) {
    debugPrint('[phone auth] ${verify ? 'verify' : 'send'} failed: ${e.statusCode} ${e.code} ${e.message}');
    final m = e.message.toLowerCase();
    if (m.contains('rate limit') || m.contains('too many') || m.contains('security purposes')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (verify && (m.contains('expired') || m.contains('invalid') || m.contains('token'))) {
      return 'That code is incorrect or has expired. Request a new one.';
    }
    if (m.contains('phone') && m.contains('disabled')) {
      return 'Phone sign-in is turned off in Supabase (Authentication → Providers → Phone).';
    }
    if (m.contains('signups not allowed') || m.contains('signup is disabled')) {
      return 'New sign-ups are turned off in Supabase (Authentication → Sign In / Providers).';
    }
    if (m.contains('database error')) {
      return 'Your account could not be created (database trigger error). Please contact ALLCURO support.';
    }
    return verify ? e.message : 'Could not send the code: ${e.message}';
  }
}

class PhoneAuthException implements Exception {
  final String message;

  const PhoneAuthException(this.message);

  @override
  String toString() => message;
}

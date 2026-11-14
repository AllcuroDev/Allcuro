import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/phone_auth.dart';
import '../../../core/network/supabase_config.dart';

/// Thrown by [AuthService.sendOtp] / [AuthService.verifyOtp] on invalid input.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Customer sign-in: phone OTP through Supabase Auth ([PhoneAuth]), with the
/// profile kept in `public.profiles` — the same data the website uses
/// (`allcuro_web/src/state/auth.ts`). SharedPreferences is only a cache so
/// screens render instantly; the Supabase session is the source of truth.
///
/// Built without Supabase keys, it runs in demo mode (code [demoOtp], local only).
class AuthService {
  static const _loggedInKey = 'auth.customer_logged_in';
  static const _onboardedKey = 'auth.customer_onboarded';
  static const _userNameKey = 'auth.customer_name';
  static const _userPhoneKey = 'auth.customer_phone';
  static const _userEmailKey = 'auth.customer_email';
  static const _userCityKey = 'auth.customer_city';
  static const _emergencyContactKey = 'auth.customer_emergency_contact';
  static const _kycTierKey = 'auth.customer_kyc_tier'; // 'light', 'id_verified'

  static const _profileKeys = [
    _userNameKey,
    _userPhoneKey,
    _userEmailKey,
    _userCityKey,
    _emergencyContactKey,
    _kycTierKey,
  ];

  static const demoOtp = PhoneAuth.demoOtp;
  static bool get isDemo => PhoneAuth.isDemo;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (!SupabaseConfig.isConfigured) return prefs.getBool(_loggedInKey) ?? false;
    final userId = PhoneAuth.currentUserId;
    if (userId == null) {
      await prefs.remove(_loggedInKey);
      return false;
    }
    await prefs.setBool(_loggedInKey, true);
    // Refresh the cache from the database; keep the cached copy if offline.
    try {
      await _syncProfile(userId);
    } catch (_) {}
    return true;
  }

  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  /// Cached profile. Only non-empty values are included so screens can fall
  /// back to their own placeholders.
  Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, String>{
      'name': prefs.getString(_userNameKey) ?? '',
      'phone': prefs.getString(_userPhoneKey) ?? '',
      'email': prefs.getString(_userEmailKey) ?? '',
      'city': prefs.getString(_userCityKey) ?? '',
      'emergencyContact': prefs.getString(_emergencyContactKey) ?? '',
      'kycTier': prefs.getString(_kycTierKey) ?? 'light',
    };
    map.removeWhere((_, v) => v.isEmpty);
    return map;
  }

  Future<void> sendOtp(String phone) async {
    try {
      await PhoneAuth.requestOtp(phone);
    } on PhoneAuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    final String? userId;
    try {
      userId = await PhoneAuth.confirmOtp(phone, otp);
    } on PhoneAuthException catch (e) {
      throw AuthException(e.message);
    }
    final prefs = await SharedPreferences.getInstance();
    final digits = PhoneAuth.digitsOf(phone);
    // A different number is a different account: drop the previous cache.
    if (prefs.getString(_userPhoneKey) != digits) {
      for (final key in _profileKeys) {
        await prefs.remove(key);
      }
      await prefs.remove(_onboardedKey);
    }
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userPhoneKey, digits);
    if (userId != null) {
      try {
        await _syncProfile(userId, phoneFallback: digits);
      } catch (_) {
        // Profile read failed (offline?) — onboarding will collect it again.
      }
    }
  }

  Future<void> completeOnboarding({
    required String name,
    required String email,
    required String city,
    required String emergencyContact,
  }) async {
    final client = supabaseOrNull;
    if (client != null) {
      final userId = PhoneAuth.currentUserId;
      if (userId == null) {
        throw const AuthException('Your session has expired. Please sign in again.');
      }
      try {
        await client.from('profiles').update({
          'full_name': name.trim(),
          'email': email.trim().isEmpty ? null : email.trim(),
          'city': city.trim(),
          'emergency_contact': emergencyContact.trim().isEmpty ? null : emergencyContact.trim(),
        }).eq('id', userId);
      } catch (_) {
        throw const AuthException('Could not save your profile. Please try again.');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name.trim());
    await prefs.setString(_userEmailKey, email.trim());
    await prefs.setString(_userCityKey, city.trim());
    await prefs.setString(_emergencyContactKey, emergencyContact.trim());
    await prefs.setBool(_onboardedKey, true);
  }

  Future<void> setKycTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycTierKey, tier);
  }

  Future<void> logout() async {
    await PhoneAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_onboardedKey);
    for (final key in _profileKeys) {
      await prefs.remove(key);
    }
  }

  /// Reads `public.profiles` for [userId] into the cache.
  Future<void> _syncProfile(String userId, {String phoneFallback = ''}) async {
    final client = supabaseOrNull;
    if (client == null) return;
    final row = await client
        .from('profiles')
        .select('full_name, phone, email, city, emergency_contact, kyc_status')
        .eq('id', userId)
        .maybeSingle();
    final rawName = (row?['full_name'] as String?)?.trim() ?? '';
    // New accounts get the placeholder name 'Member' from the signup trigger.
    final name = rawName == 'Member' ? '' : rawName;
    final phoneDigits = PhoneAuth.digitsOf((row?['phone'] as String?) ?? phoneFallback);
    final phone = phoneDigits.length > 10 ? phoneDigits.substring(phoneDigits.length - 10) : phoneDigits;
    // profiles.city defaults to 'Bengaluru'; only a named profile counts as set up.
    final city = name.isEmpty ? '' : ((row?['city'] as String?) ?? '');

    final prefs = await SharedPreferences.getInstance();
    Future<void> put(String key, String value) =>
        value.isEmpty ? prefs.remove(key) : prefs.setString(key, value);
    await put(_userNameKey, name);
    await put(_userPhoneKey, phone);
    await put(_userEmailKey, (row?['email'] as String?) ?? '');
    await put(_userCityKey, city);
    await put(_emergencyContactKey, (row?['emergency_contact'] as String?) ?? '');
    await prefs.setString(_kycTierKey, row?['kyc_status'] == 'verified' ? 'id_verified' : 'light');
    await prefs.setBool(_onboardedKey, name.isNotEmpty && city.isNotEmpty);
  }
}

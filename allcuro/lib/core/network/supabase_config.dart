import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project keys, passed at build time so they never live in source:
///
///   flutter run --dart-define-from-file=supabase.json
///
/// (copy `supabase.example.json` → `supabase.json`). Without them
/// [supabaseOrNull] stays null: the services catalog falls back to its bundled
/// copy, and partners, equipment, medicines and bookings are simply empty.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}

/// The shared client, or null when the app was built without Supabase keys.
SupabaseClient? get supabaseOrNull => SupabaseConfig.isConfigured ? Supabase.instance.client : null;

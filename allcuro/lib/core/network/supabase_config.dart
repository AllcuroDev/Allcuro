import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project keys, passed at build time so they never live in source:
///
///   flutter run --dart-define-from-file=supabase.json
///
/// (copy `supabase.example.json` → `supabase.json`). Without them the app runs
/// on its bundled demo data and [supabaseOrNull] stays null.
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

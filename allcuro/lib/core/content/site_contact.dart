import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/supabase_config.dart';

/// ALLCURO's care-desk contact details, edited by the admin in
/// `public.site_settings` (key `contact`). Empty strings when the app runs
/// without Supabase or the row is missing — screens then simply leave the
/// number out instead of showing a made-up one.
@immutable
class SiteContact {
  final String phoneDisplay;
  final String phone;
  final String whatsapp;
  final String email;

  const SiteContact({this.phoneDisplay = '', this.phone = '', this.whatsapp = '', this.email = ''});

  static const empty = SiteContact();

  bool get hasPhone => phoneDisplay.isNotEmpty;

  factory SiteContact.fromJson(Map<String, dynamic> json) {
    String s(String key) => (json[key] ?? '').toString().trim();
    final display = s('phoneDisplay');
    return SiteContact(
      phoneDisplay: display.isNotEmpty ? display : s('phone'),
      phone: s('phone'),
      whatsapp: s('whatsapp'),
      email: s('email'),
    );
  }
}

final siteContactProvider = FutureProvider<SiteContact>((ref) async {
  final client = supabaseOrNull;
  if (client == null) return SiteContact.empty;
  try {
    final row = await client.from('site_settings').select('value').eq('key', 'contact').maybeSingle();
    final value = row?['value'];
    if (value is Map) return SiteContact.fromJson(Map<String, dynamic>.from(value));
  } catch (e) {
    debugPrint('Site contact: not loaded — $e');
  }
  return SiteContact.empty;
});

/// The care-desk number once loaded, or '' (never a placeholder number).
final careDeskPhoneProvider = Provider<String>(
  (ref) => ref.watch(siteContactProvider).valueOrNull?.phoneDisplay ?? '',
);

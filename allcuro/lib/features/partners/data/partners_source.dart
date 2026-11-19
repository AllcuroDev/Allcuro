import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_config.dart';

/// Approved partners as the customer app may see them: rows of the
/// `partners_public` view (approved only) plus their admin-priced rates from
/// `partner_offerings_public`. Mirrors allcuro_web/src/state/content.ts.
///
/// Without Supabase keys, or on any error, this is empty — the app never
/// invents partners.
@immutable
class PartnerRows {
  final List<Map<String, dynamic>> partners;
  final Map<String, List<Map<String, dynamic>>> offeringsByPartner;

  const PartnerRows({this.partners = const [], this.offeringsByPartner = const {}});

  static const empty = PartnerRows();
}

class PartnersSource {
  const PartnersSource();

  Future<PartnerRows> fetch() async {
    final client = supabaseOrNull;
    if (client == null) return PartnerRows.empty;
    try {
      final results = await Future.wait([
        client.from('partners_public').select('*').order('rating', ascending: false, nullsFirst: false),
        client.from('partner_offerings_public').select('*').order('sort_order'),
      ]);
      final offers = <String, List<Map<String, dynamic>>>{};
      for (final o in results[1]) {
        offers.putIfAbsent(o['partner_id'].toString(), () => []).add(o);
      }
      return PartnerRows(partners: List<Map<String, dynamic>>.from(results[0]), offeringsByPartner: offers);
    } catch (e) {
      debugPrint('Partners: not loaded — $e');
      return PartnerRows.empty;
    }
  }
}

final partnersSourceProvider = Provider<PartnersSource>((ref) => const PartnersSource());

/// One fetch shared by the nurses and centres repositories.
final partnerRowsProvider = FutureProvider<PartnerRows>((ref) => ref.watch(partnersSourceProvider).fetch());

// ------------------------------------------------------------ row helpers

String rowText(Map<String, dynamic> r, String key) => (r[key] ?? '').toString();

List<String> rowList(Map<String, dynamic> r, String key) =>
    (r[key] as List?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() ?? const [];

int rowInt(Map<String, dynamic> r, String key) => (r[key] as num?)?.round() ?? 0;

double rowDouble(Map<String, dynamic> r, String key) => (r[key] as num?)?.toDouble() ?? 0;

/// Price after a percentage discount, rounded to the rupee (same as the web).
int discounted(num price, num? percent) => (price * (1 - (percent ?? 0) / 100)).round();

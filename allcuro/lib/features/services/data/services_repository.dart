import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_config.dart';
import 'master_services_catalog.dart';

/// Loads the public services catalog from Supabase (`public.services`, readable
/// without login — see supabase/services.sql) and swaps it into
/// [MasterServicesCatalog]. Screens watch this so they rebuild once it lands;
/// on any failure they keep the bundled catalog.
final servicesCatalogProvider = FutureProvider<List<MasterServiceItem>>((ref) async {
  final client = supabaseOrNull;
  if (client == null) return MasterServicesCatalog.bundledServices;
  try {
    final rows = await client
        .from('services')
        .select(
          'id, name, category_id, subcategory, description, includes, not_included, '
          'duration, professional, price, notes, badge, icon, image_url',
        )
        .order('sort_order');
    if (rows.isEmpty) return MasterServicesCatalog.bundledServices;
    final live = rows.map(_fromRow).toList();
    MasterServicesCatalog.replaceAll(live);
    return live;
  } catch (e) {
    debugPrint('Services: using bundled catalog — $e');
    return MasterServicesCatalog.bundledServices;
  }
});

MasterServiceItem _fromRow(Map<String, dynamic> r) {
  final id = r['id'] as String;
  String text(String key) => (r[key] as String?) ?? '';
  // Material glyphs aren't stored server-side; reuse the bundled one for known
  // services. Grid tiles draw the care icon/artwork from the `icon` key.
  final bundled = MasterServicesCatalog.bundledServices.where((s) => s.id == id).firstOrNull;
  return MasterServiceItem(
    id: id,
    name: text('name'),
    mainCategory: text('category_id'),
    subcategory: text('subcategory'),
    description: text('description'),
    includes: text('includes'),
    notIncluded: text('not_included'),
    duration: text('duration'),
    professional: text('professional'),
    price: text('price'),
    notes: text('notes').isEmpty ? '—' : text('notes'),
    icon: bundled?.icon ?? Icons.medical_services_rounded,
    iconKey: text('icon'),
    imageUrl: r['image_url'] as String?,
    badge: text('badge'),
  );
}

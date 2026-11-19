import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_config.dart';

/// A medicine sold through ALLCURO's partner pharmacy. Prices are in rupees
/// and GST-inclusive. Loaded from `public.medicines` (same rows as the website).
@immutable
class Medicine {
  final String id;
  final String name;
  final String pack;
  final int mrp;
  final int price;

  /// Prescription-only: ordering it needs an uploaded prescription.
  final bool rx;
  final String category;
  final String? imageUrl;

  const Medicine({
    required this.id,
    required this.name,
    required this.pack,
    required this.mrp,
    required this.price,
    required this.rx,
    required this.category,
    this.imageUrl,
  });

  int get discountPercent => mrp <= 0 ? 0 : (((mrp - price) / mrp) * 100).round();
}

/// The medicines the partner pharmacy sells, from Supabase `public.medicines`
/// (is_active rows). Starts empty and is filled by [medicineCatalogProvider];
/// without Supabase it stays empty — there is no bundled list.
class MedicineCatalog {
  MedicineCatalog._();

  static List<Medicine> _all = const [];

  static List<Medicine> get all => _all;

  /// 'All' plus every category that has at least one medicine.
  static List<String> get categories => [
        'All',
        ...{for (final m in _all) if (m.category.isNotEmpty) m.category},
      ];

  static void replaceAll(List<Medicine> medicines) => _all = List.unmodifiable(medicines);

  static Medicine? byId(String id) {
    for (final m in _all) {
      if (m.id == id) return m;
    }
    return null;
  }

  static List<Medicine> search(String query, {String category = 'All'}) {
    final q = query.trim().toLowerCase();
    return _all.where((m) {
      if (category != 'All' && m.category != category) return false;
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q) ||
          m.pack.toLowerCase().contains(q);
    }).toList();
  }
}

Medicine medicineFromRow(Map<String, dynamic> r) => Medicine(
      id: r['id'].toString(),
      name: (r['name'] ?? '').toString(),
      pack: (r['pack'] ?? '').toString(),
      category: (r['category'] ?? '').toString(),
      mrp: (r['mrp'] as num?)?.round() ?? 0,
      price: (r['price'] as num?)?.round() ?? 0,
      rx: r['rx'] as bool? ?? false,
      imageUrl: r['image_url'] as String?,
    );

/// Loads the medicines catalog and swaps it into [MedicineCatalog]; screens
/// watch this so they rebuild once it lands.
final medicineCatalogProvider = FutureProvider<List<Medicine>>((ref) async {
  final client = supabaseOrNull;
  if (client == null) return MedicineCatalog.all;
  try {
    final rows = await client
        .from('medicines')
        .select('id, name, pack, category, mrp, price, rx, image_url')
        .eq('is_active', true)
        .order('sort_order');
    MedicineCatalog.replaceAll(rows.map(medicineFromRow).toList());
  } catch (e) {
    debugPrint('Medicines: not loaded — $e');
  }
  return MedicineCatalog.all;
});

/// Pricing rules shared with the website: free delivery from ₹499,
/// otherwise a ₹39 fee. Medicine prices already include GST.
class MedicinePricing {
  MedicinePricing._();

  static const freeDeliveryFrom = 499;
  static const deliveryFee = 39;
  static const maxQty = 10;
}

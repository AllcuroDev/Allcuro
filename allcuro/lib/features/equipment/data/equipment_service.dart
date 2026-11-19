import 'package:flutter/foundation.dart';

import '../../../core/network/supabase_config.dart';
import '../../partners/data/partners_source.dart';
import 'models/equipment.dart';

/// Rentable equipment from `public.equipment` (is_active rows, admin-set
/// rates and discount). Empty without Supabase or when nothing is listed.
class EquipmentService {
  const EquipmentService();

  Future<List<Equipment>> fetchAll() async {
    final client = supabaseOrNull;
    if (client == null) return const [];
    try {
      final rows = await client.from('equipment').select('*').eq('is_active', true).order('sort_order');
      return rows.map(equipmentFromRow).toList();
    } catch (e) {
      debugPrint('Equipment: not loaded — $e');
      return const [];
    }
  }

  /// Categories present in [items], in first-seen order.
  static List<String> categoriesOf(List<Equipment> items) =>
      {for (final e in items) if (e.category.isNotEmpty) e.category}.toList();
}

Equipment equipmentFromRow(Map<String, dynamic> r) {
  final discount = r['discount_percent'] as num?;
  final stock = r['stock_quantity'] as num?;
  return Equipment(
    id: rowText(r, 'slug').isNotEmpty ? rowText(r, 'slug') : rowText(r, 'id'),
    name: rowText(r, 'title'),
    category: rowText(r, 'category'),
    photo: rowText(r, 'photo_url'),
    description: rowText(r, 'description'),
    features: rowList(r, 'features'),
    perDay: discounted((r['daily_rate'] as num?) ?? 0, discount),
    perMonth: discounted((r['monthly_rate'] as num?) ?? 0, discount),
    deposit: rowInt(r, 'deposit_amount'),
    condition: rowText(r, 'condition'),
    availableIn: rowText(r, 'available_pincodes'),
    inStock: (r['is_available'] as bool? ?? true) && (stock ?? 1) > 0,
  );
}

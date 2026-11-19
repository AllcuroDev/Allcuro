import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/pricing_breakdown.dart';

/// There's no live pricing/payment backend yet, so this repository derives
/// the breakdown locally. Once checkout talks to a real service, only the
/// body of [calculateBreakdown] needs to change — callers are unaffected.
class CheckoutRepository {
  const CheckoutRepository();

  /// Catalog prices already carry the admin's discount; no extra promo here.
  static const _discount = 0;
  static const _fee = 99;
  static const _gstRate = 0.18;

  Future<PricingBreakdown> calculateBreakdown({required int base}) async {
    final gst = ((base - _discount + _fee) * _gstRate).round();
    final total = base - _discount + _fee + gst;
    return PricingBreakdown(base: base, discount: _discount, fee: _fee, gst: gst, total: total);
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) => const CheckoutRepository());

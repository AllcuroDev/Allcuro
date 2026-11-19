import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checkout_repository.dart';
import '../data/models/pricing_breakdown.dart';

/// Price breakdown for the item being checked out; [arg] is its base price
/// (from the live catalog, passed in by the screen that opened checkout).
class CheckoutViewModel extends FamilyAsyncNotifier<PricingBreakdown, int> {
  @override
  Future<PricingBreakdown> build(int arg) {
    return ref.watch(checkoutRepositoryProvider).calculateBreakdown(base: arg);
  }
}

final checkoutViewModelProvider =
    AsyncNotifierProvider.family<CheckoutViewModel, PricingBreakdown, int>(CheckoutViewModel.new);

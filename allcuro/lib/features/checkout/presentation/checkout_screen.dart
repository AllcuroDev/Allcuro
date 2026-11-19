import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/site_contact.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/screen_header.dart';
import '../../../core/ui/surface.dart';
import '../../../core/utils/currency.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../bookings/data/bookings_service.dart';
import '../../bookings/data/models/booking.dart';
import '../../location/presentation/location_view_model.dart';
import '../../bookings/presentation/bookings_view_model.dart';
import '../data/models/pricing_breakdown.dart';
import 'checkout_view_model.dart';

const _steps = [
  'Select service & dates',
  'Confirm requirement',
  'Address',
  'Review price',
  'Payment',
];

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? item;

  /// Base price from the live catalog; null/0 → nothing to check out.
  final int? price;

  /// 'day' or 'month' — the rental period [price] covers.
  final String? unit;

  const CheckoutScreen({super.key, this.item, this.price, this.unit});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessingPayment = false;

  void _handlePayment(PricingBreakdown breakdown) async {
    setState(() => _isProcessingPayment = true);

    // No payment gateway is wired up yet; the booking is recorded on the device.
    await Future.delayed(const Duration(milliseconds: 900));

    final itemName = widget.item?.trim().isNotEmpty == true ? widget.item!.trim() : 'Equipment rental';
    final address = ref.read(locationViewModelProvider).currentAddress;
    final auth = ref.read(authViewModelProvider);

    final newBooking = Booking(
      id: newBookingId('EQP'),
      type: BookingType.equipment,
      title: itemName,
      when: widget.unit == 'day' ? 'Daily rental · delivery date confirmed on call' : 'Monthly rental · delivery date confirmed on call',
      status: 'Confirmed',
      amount: breakdown.total,
      otp: newVisitOtp(),
      liveStatus: BookingLiveStatus.assigned,
      patientName: auth.userProfile['name'] ?? '',
      address: address.fullAddress,
      locality: address.shortAddress,
      providerName: 'ALLCURO equipment desk',
      providerPhone: ref.read(careDeskPhoneProvider),
      formalities: const [],
    );

    await ref.read(bookingsViewModelProvider.notifier).createBooking(newBooking);

    if (mounted) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booked $itemName · our team will call to schedule delivery.')),
      );
      context.go('/bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.price ?? 0;
    if (price <= 0) {
      return AppShell(
        currentPath: '/checkout',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ScreenHeader(
              title: 'Checkout & Payment',
              subtitle: 'Nothing to check out',
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Nothing to check out yet',
              message: 'Pick an item from the equipment catalogue to rent it.',
              action: OutlinedButton(
                onPressed: () => context.go('/equipment'),
                child: const Text('Browse equipment'),
              ),
            ),
          ],
        ),
      );
    }
    final breakdownAsync = ref.watch(checkoutViewModelProvider(price));

    return AppShell(
      currentPath: '/checkout',
      bottomBar: breakdownAsync.maybeWhen(
        data: (breakdown) => _BottomBar(
          breakdown: breakdown,
          isProcessing: _isProcessingPayment,
          onPay: () => _handlePayment(breakdown),
        ),
        orElse: () => null,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Checkout & Payment',
            subtitle: widget.item != null && widget.item!.isNotEmpty
                ? 'Booking: ${widget.item}'
                : 'Confirm your booking',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          breakdownAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (error, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Could not load pricing',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            ),
            data: (breakdown) => _CheckoutBody(breakdown: breakdown, unit: widget.unit),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final PricingBreakdown breakdown;
  final bool isProcessing;
  final VoidCallback onPay;

  const _BottomBar({
    required this.breakdown,
    required this.isProcessing,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PAYABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  inr(breakdown.total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: ElevatedButton(
            onPressed: isProcessing ? null : onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
              elevation: 0,
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Pay securely',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  final PricingBreakdown breakdown;
  final String? unit;

  const _CheckoutBody({required this.breakdown, this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(
                radius: AppRadius.xl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i < 4 ? AppColors.primary : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i < 4 ? AppColors.primaryForeground : AppColors.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_steps[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Surface(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PRICE BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.mutedForeground)),
                const SizedBox(height: 12),
                _Row(label: unit == 'day' ? 'Rent (1 day)' : 'Rent (1 month)', value: inr(breakdown.base)),
                const SizedBox(height: 8),
                if (breakdown.discount > 0) ...[
                  _Row(label: 'Discount', value: '- ${inr(breakdown.discount)}'),
                  const SizedBox(height: 8),
                ],
                _Row(label: 'Platform fee', value: inr(breakdown.fee)),
                const SizedBox(height: 8),
                _Row(label: 'GST (18%)', value: inr(breakdown.gst)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text(inr(breakdown.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xxxl),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Have a coupon?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(AppRadius.lg)),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter code',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coupon code applied successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        elevation: 0,
                      ),
                      child: const Text('Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.push('/bookings'),
              child: const Text('View my bookings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground))),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/screen_header.dart';
import '../../../core/ui/surface.dart';
import '../../../core/utils/currency.dart';
import '../../bookings/data/models/booking.dart';
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

  const CheckoutScreen({super.key, this.item});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessingPayment = false;

  void _handlePayment(PricingBreakdown breakdown) async {
    setState(() => _isProcessingPayment = true);

    // Simulate secure Razorpay gateway processing
    await Future.delayed(const Duration(milliseconds: 900));

    final itemName = widget.item ?? 'Home Nursing Care';
    final isCentre = itemName.toLowerCase().contains('centre') ||
        itemName.toLowerCase().contains('rehab') ||
        itemName.toLowerCase().contains('garden') ||
        itemName.toLowerCase().contains('elder care') ||
        itemName.toLowerCase().contains('sanjeevani');

    final bookingId = isCentre ? 'ALC-CTR-4920' : 'ALC-NUR-8921';
    final otp = isCentre ? '7391' : '4829';

    final newBooking = Booking(
      id: bookingId,
      type: isCentre ? BookingType.careCentre : BookingType.nurse,
      title: isCentre ? '$itemName · Deluxe Room' : '$itemName · Post-Op Care',
      when: isCentre ? 'Check-in: Tomorrow, 10:00 AM · 30 Days' : 'Today · 08:00 AM – 08:00 PM',
      status: isCentre ? 'Confirmed' : 'In Progress',
      amount: breakdown.total,
      otp: otp,
      liveStatus: isCentre ? BookingLiveStatus.assigned : BookingLiveStatus.enRoute,
      patientName: 'Ramesh Iyer',
      patientAge: 68,
      patientGender: 'Male',
      address: 'Flat 402, Green Glen Palms, 12th Main, Indiranagar, Bengaluru',
      locality: 'Indiranagar, Bengaluru',
      providerName: isCentre ? itemName : 'Priya Sharma',
      providerPhone: isCentre ? '+91 80 4120 5500' : '+91 98450 12345',
      providerRating: 4.92,
      providerQualifications: isCentre
          ? 'Field Audited · 1:3 Nurse Ratio · Fire & NABH NOC'
          : 'GNM · 4 yrs exp · HPR Verified',
      roomType: isCentre ? 'Deluxe Room with Attached Bath' : null,
      condition: 'Post-op knee recovery & IV antibiotics administration',
      vitalsSummary: isCentre ? null : 'Vitals logging in progress by nurse...',
      formalities: isCentre
          ? const [
              'Govt Photo ID (Aadhaar / Passport) of patient',
              'Hospital Discharge Summary & Doctor Prescription',
              'Digital Admission Pass & Check-In OTP (7391)',
              'Signed Care Agreement & Emergency Contact Consent',
            ]
          : const [],
    );

    await ref.read(bookingsViewModelProvider.notifier).createBooking(newBooking);

    if (mounted) {
      setState(() => _isProcessingPayment = false);
      if (isCentre) {
        context.push('/centre-pass/$bookingId');
      } else {
        context.push('/nurse-tracker/$bookingId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdownAsync = ref.watch(checkoutViewModelProvider);

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
            data: (breakdown) => _CheckoutBody(breakdown: breakdown),
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

  const _CheckoutBody({required this.breakdown});

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
                _Row(label: 'Base cost', value: inr(breakdown.base)),
                const SizedBox(height: 8),
                _Row(label: 'First booking discount', value: '- ${inr(breakdown.discount)}'),
                const SizedBox(height: 8),
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

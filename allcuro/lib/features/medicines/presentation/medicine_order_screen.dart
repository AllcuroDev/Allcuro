import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/screen_header.dart';
import '../../../core/utils/currency.dart';
import '../../bookings/data/models/booking.dart';
import '../../bookings/presentation/bookings_view_model.dart';

/// Order placed → tracking: delivery OTP, status timeline, items and address.
class MedicineOrderScreen extends ConsumerWidget {
  final String orderId;

  const MedicineOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(singleBookingProvider(orderId));

    return AppShell(
      currentPath: '/bookings',
      child: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => const Center(
          child: Text('Could not load this order', style: TextStyle(color: AppColors.mutedForeground)),
        ),
        data: (order) => order == null || order.type != BookingType.medicine
            ? const Center(
                child: Text('Order not found', style: TextStyle(color: AppColors.mutedForeground)),
              )
            : _OrderBody(order: order),
      ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  final Booking order;

  const _OrderBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final verified = order.prescriptionName == null;
    final steps = [
      ('Order placed', 'We have your order', true),
      (
        'Pharmacist verified',
        verified ? 'No prescription needed' : 'Checking ${order.prescriptionName}',
        verified,
      ),
      ('Packed', 'At the partner pharmacy', false),
      ('Out for delivery', 'Share the OTP with the rider', false),
      ('Delivered', order.when, false),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          title: 'Order confirmed',
          subtitle: '${order.id} · ${order.when}',
          onBack: () => context.canPop() ? context.pop() : context.go('/bookings'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${inr(order.amount)} · ${order.providerQualifications.split(' · ').last}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Share the delivery OTP only when your medicines arrive.',
                        style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFFD1FAE5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'OTP',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.mutedForeground),
                      ),
                      Text(
                        order.otp,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Order status',
          child: Column(
            children: [
              for (int i = 0; i < steps.length; i++)
                _StatusStep(
                  title: steps[i].$1,
                  subtitle: steps[i].$2,
                  done: steps[i].$3,
                  current: !steps[i].$3 && (i == 0 || steps[i - 1].$3),
                  isLast: i == steps.length - 1,
                ),
            ],
          ),
        ),
        _Section(
          title: 'Items',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.medication_outlined, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.ink)),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 16, color: AppColors.border),
              Row(
                children: [
                  const Expanded(
                    child: Text('Total paid', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ),
                  Text(inr(order.amount), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                ],
              ),
            ],
          ),
        ),
        _Section(
          title: 'Delivering to',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.address,
                  style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: OutlinedButton.icon(
            onPressed: () => context.go('/bookings'),
            icon: const Icon(Icons.event_available_outlined, size: 18),
            label: const Text('View all bookings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final bool current;
  final bool isLast;

  const _StatusStep({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.current,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.primary : (current ? AppColors.warning : AppColors.border);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: done ? AppColors.primary : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: done || current ? AppColors.ink : AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

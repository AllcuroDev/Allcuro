import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/screen_header.dart';
import '../../../core/ui/surface.dart';
import '../../../core/utils/currency.dart';
import '../data/models/booking.dart';
import 'bookings_view_model.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsViewModelProvider);

    return AppShell(
      currentPath: '/bookings',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(title: 'My Bookings', subtitle: 'Nurses, centres, equipment & medicines'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: bookingsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Could not load bookings', style: TextStyle(color: AppColors.mutedForeground))),
              ),
              data: (bookings) => Column(
                children: bookings.map((b) => _BookingCard(booking: b)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final isNurse = b.type == BookingType.nurse;
    final isCentre = b.type == BookingType.careCentre;
    final isMedicine = b.type == BookingType.medicine;
    final isCompleted = b.status == 'Completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Surface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isNurse
                        ? AppColors.primarySoft
                        : (isCentre ? AppColors.secondary : AppColors.secondary),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNurse
                        ? Icons.medical_services_outlined
                        : isCentre
                            ? Icons.apartment_outlined
                            : isMedicine
                                ? Icons.medication_outlined
                                : Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.when,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                      ),
                      if (isMedicine && b.items.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          b.items.map((i) => i.split(' · ').first).join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.ink),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.secondary : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    b.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isCompleted ? AppColors.mutedForeground : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // OTP Badge & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_outlined, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'OTP: ${b.otp}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    b.id,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mutedForeground),
                  ),
                Text(
                  inr(b.amount),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),

            if (!isCompleted) ...[
              const SizedBox(height: 12),
              if (isNurse)
                ElevatedButton.icon(
                  onPressed: () => context.push('/nurse-tracker/${b.id}'),
                  icon: const Icon(Icons.radar_rounded, size: 16),
                  label: const Text('Live Track Nurse & View OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                )
              else if (isMedicine)
                ElevatedButton.icon(
                  onPressed: () => context.push('/medicine-order/${b.id}'),
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: const Text('Track Order & View OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                )
              else if (isCentre)
                ElevatedButton.icon(
                  onPressed: () => context.push('/centre-pass/${b.id}'),
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: const Text('View Digital Admission Pass & OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

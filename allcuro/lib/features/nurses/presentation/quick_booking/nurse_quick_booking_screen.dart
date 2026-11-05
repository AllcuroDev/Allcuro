import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/utils/currency.dart';
import '../../../bookings/data/models/booking.dart';
import '../../../bookings/presentation/bookings_view_model.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../auth/presentation/quick_login_sheet.dart';

class QuickServiceOption {
  final String title;
  final String duration;
  final int price;
  final IconData icon;
  final String description;

  const QuickServiceOption({
    required this.title,
    required this.duration,
    required this.price,
    required this.icon,
    required this.description,
  });
}

const _quickServices = [
  QuickServiceOption(
    title: 'Vital Signs & Health Monitoring',
    duration: '45 mins visit',
    price: 499,
    icon: Icons.monitor_heart_outlined,
    description: 'BP, Blood Sugar, SpO2, Pulse, Temp & clinical charting.',
  ),
  QuickServiceOption(
    title: 'Post-Op Wound Dressing & IV',
    duration: '1 hr visit',
    price: 999,
    icon: Icons.healing_outlined,
    description: 'Surgical wound cleaning, sterile dressing & IV infusion.',
  ),
  QuickServiceOption(
    title: '12-Hour Day Shift Nursing',
    duration: '12 hours (8 AM - 8 PM)',
    price: 1600,
    icon: Icons.access_time_filled_outlined,
    description: 'Dedicated post-op recovery, medication & toilet care.',
  ),
  QuickServiceOption(
    title: '24-Hour Live-in Attendant Care',
    duration: '24 hours / full-day',
    price: 2800,
    icon: Icons.bed_outlined,
    description: '24x7 mobility, feeding, hygiene & overnight assistance.',
  ),
];

const _timeSlots = [
  '⚡ Instant (Arrives in 30–45 mins)',
  'Today · Afternoon (02:00 PM – 08:00 PM)',
  'Today · Night Shift (08:00 PM – 08:00 AM)',
  'Tomorrow · Morning (08:00 AM – 02:00 PM)',
];

class NurseQuickBookingScreen extends ConsumerStatefulWidget {
  const NurseQuickBookingScreen({super.key});

  @override
  ConsumerState<NurseQuickBookingScreen> createState() =>
      _NurseQuickBookingScreenState();
}

class _NurseQuickBookingScreenState
    extends ConsumerState<NurseQuickBookingScreen> {
  int _selectedServiceIdx = 1; // Default to Post-Op Wound Dressing & IV
  int _selectedSlotIdx = 0; // Default to Instant
  final _nameController = TextEditingController(text: 'Ramesh Iyer');
  final _ageController = TextEditingController(text: '68');
  final _addressController = TextEditingController(
    text: 'Flat 402, Green Glen Palms, 12th Main, Indiranagar, Bengaluru',
  );
  final _notesController = TextEditingController(
    text: 'Post-op knee surgery recovery. Requires Cefuroxime IV and sterile wound dressing.',
  );
  String _gender = 'Male';
  bool _isBooking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitBooking() async {
    final authState = ref.read(authViewModelProvider);
    final isAuthenticated =
        authState.status == AuthStatus.onboarded || authState.status == AuthStatus.authenticated;

    if (!isAuthenticated) {
      QuickLoginSheet.show(
        context,
        title: 'Quick Login to Confirm',
        subtitle: 'Enter your phone number to complete and track your booking',
        onSuccess: _submitBooking,
      );
      return;
    }

    setState(() => _isBooking = true);
    final selectedService = _quickServices[_selectedServiceIdx];
    final selectedTiming = _timeSlots[_selectedSlotIdx];

    final newBooking = Booking(
      id: 'ALC-NUR-8921',
      type: BookingType.nurse,
      title: 'Priya Sharma (GNM) · ${selectedService.title}',
      when: selectedTiming,
      status: 'In Progress',
      amount: selectedService.price + 149, // + platform fee
      otp: '4829',
      liveStatus: BookingLiveStatus.enRoute,
      patientName: _nameController.text.trim().isEmpty ? 'Ramesh Iyer' : _nameController.text.trim(),
      patientAge: int.tryParse(_ageController.text) ?? 68,
      patientGender: _gender,
      address: _addressController.text.trim().isEmpty
          ? 'Flat 402, Green Glen Palms, Indiranagar, Bengaluru'
          : _addressController.text.trim(),
      locality: 'Indiranagar, Bengaluru',
      providerName: 'Priya Sharma',
      providerPhone: '+91 98450 12345',
      providerRating: 4.92,
      providerQualifications: 'GNM · 4 yrs exp · HPR Verified',
      condition: _notesController.text.trim(),
      vitalsSummary: 'Vitals logging in progress by nurse...',
    );

    await ref.read(bookingsViewModelProvider.notifier).createBooking(newBooking);

    if (mounted) {
      setState(() => _isBooking = false);
      context.push('/nurse-tracker/${newBooking.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedService = _quickServices[_selectedServiceIdx];
    final basePrice = selectedService.price;
    final platformFee = 99;
    final gst = ((basePrice + platformFee) * 0.18).toInt();
    final totalPrice = basePrice + platformFee + gst;

    return AppShell(
      currentPath: '/nurse-quick-booking',
      bottomBar: Container(
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
                      letterSpacing: 1.0,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  Text(
                    inr(totalPrice),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isBooking ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Book Nurse Now',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Quick Nurse Booking',
            subtitle: 'Verified home nursing delivered in 30-45 mins',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trust banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '100% Govt ID & HPR Registered Nurses · Police Checked · Clinical Grade Safety',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 1. Select Service Type
                const Text(
                  '1. Select Nursing Service',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                ..._quickServices.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final isSelected = _selectedServiceIdx == idx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedServiceIdx = idx),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primarySoft.withValues(alpha: 0.4) : AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                s.icon,
                                color: isSelected ? Colors.white : AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.title,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        inr(s.price),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.duration} · ${s.description}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // 2. Select Timing
                const Text(
                  '2. Timing & Shift Slot',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                ..._timeSlots.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final slot = entry.value;
                  final isSelected = _selectedSlotIdx == idx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSlotIdx = idx),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.secondary : AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryDeep : AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // 3. Patient Details
                const Text(
                  '3. Patient Information',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Surface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Full Name',
                          hintText: 'e.g. Ramesh Iyer',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                hintText: '68',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _gender = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Service Address (Home)',
                          hintText: 'House / flat, street, locality',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Medical Condition & Special Instructions',
                          hintText: 'e.g. Post-op knee recovery, IV antibiotics',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Pricing Breakdown
                const Text(
                  '4. Bill Summary',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Surface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PriceRow(label: selectedService.title, amount: inr(basePrice)),
                      const SizedBox(height: 6),
                      _PriceRow(label: 'ALLCURO Quality & Safety Fee', amount: inr(platformFee)),
                      const SizedBox(height: 6),
                      _PriceRow(label: 'GST (18%)', amount: inr(gst)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      _PriceRow(
                        label: 'Total Payable',
                        amount: inr(totalPrice),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 13.5 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? AppColors.ink : AppColors.mutedForeground,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

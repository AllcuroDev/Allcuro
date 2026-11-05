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

class RoomOption {
  final String title;
  final int pricePerDay;
  final String description;
  final IconData icon;

  const RoomOption({
    required this.title,
    required this.pricePerDay,
    required this.description,
    required this.icon,
  });
}

const _roomOptions = [
  RoomOption(
    title: 'General Shared Ward',
    pricePerDay: 1500,
    description: '3-bed shared room with 24x7 nursing & assisted meals.',
    icon: Icons.meeting_room_outlined,
  ),
  RoomOption(
    title: 'Semi-Private Room (Twin Sharing)',
    pricePerDay: 2200,
    description: 'Twin sharing room with AC, private wardrobe & 1:4 nurse ratio.',
    icon: Icons.bed_outlined,
  ),
  RoomOption(
    title: 'Private Deluxe Room',
    pricePerDay: 3500,
    description: 'Dedicated private room, attached bath, TV & 1:2 caregiver ratio.',
    icon: Icons.king_bed_outlined,
  ),
  RoomOption(
    title: 'ICU Step-Down / High Dependency',
    pricePerDay: 5500,
    description: 'Continuous vitals monitoring, oxygen/BiPAP line & dedicated nurse.',
    icon: Icons.local_hospital_outlined,
  ),
];

const _durations = [
  (days: 7, label: '7 Days (Short Stay)'),
  (days: 15, label: '15 Days (Recovery)'),
  (days: 30, label: '30 Days (Monthly Care)'),
];

class CentreBookingScreen extends ConsumerStatefulWidget {
  final String centreId;

  const CentreBookingScreen({super.key, required this.centreId});

  @override
  ConsumerState<CentreBookingScreen> createState() =>
      _CentreBookingScreenState();
}

class _CentreBookingScreenState extends ConsumerState<CentreBookingScreen> {
  int _selectedRoomIdx = 2; // Default Private Deluxe
  int _selectedDurationIdx = 2; // Default 30 days
  final _nameController = TextEditingController(text: 'Kavita Nair');
  final _ageController = TextEditingController(text: '74');
  final _addressController = TextEditingController(
    text: 'Sanjeevani Elder Care, 4th Cross, 100ft Road, Indiranagar, Bengaluru',
  );
  final _notesController = TextEditingController(
    text: 'Post-stroke physical rehabilitation and medication assistance.',
  );
  String _gender = 'Female';
  bool _isBooking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitCentreBooking() async {
    setState(() => _isBooking = true);
    final room = _roomOptions[_selectedRoomIdx];
    final duration = _durations[_selectedDurationIdx];
    final totalStayAmount = room.pricePerDay * duration.days;

    final newBooking = Booking(
      id: 'ALC-CTR-4920',
      type: BookingType.careCentre,
      title: 'Sanjeevani Elder Care · ${room.title}',
      when: 'Check-in: Tomorrow, 10:00 AM · ${duration.days} Days',
      status: 'Confirmed',
      amount: totalStayAmount,
      otp: '7391',
      liveStatus: BookingLiveStatus.assigned,
      patientName: _nameController.text.trim().isEmpty ? 'Kavita Nair' : _nameController.text.trim(),
      patientAge: int.tryParse(_ageController.text) ?? 74,
      patientGender: _gender,
      address: 'Sanjeevani Elder Care Home, 4th Cross, 100ft Road, Indiranagar, Bengaluru',
      locality: 'Indiranagar, Bengaluru',
      providerName: 'Sanjeevani Elder Care Home',
      providerPhone: '+91 80 4120 5500',
      providerRating: 4.88,
      providerQualifications: 'Field Audited · 1:3 Nurse Ratio · NABH Compliant',
      roomType: room.title,
      condition: _notesController.text.trim(),
      formalities: const [
        'Govt Photo ID (Aadhaar / Passport) of patient',
        'Hospital Discharge Summary & Doctor Prescription',
        'Digital Admission Pass & Check-In OTP (7391)',
        'Signed Care Agreement & Emergency Contact Consent',
      ],
    );

    await ref.read(bookingsViewModelProvider.notifier).createBooking(newBooking);

    if (mounted) {
      setState(() => _isBooking = false);
      context.push('/centre-pass/${newBooking.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _roomOptions[_selectedRoomIdx];
    final duration = _durations[_selectedDurationIdx];
    final stayTotal = room.pricePerDay * duration.days;
    final refundableDeposit = 5000;
    final grandTotal = stayTotal + refundableDeposit;

    return AppShell(
      currentPath: '/centres',
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
                    'TOTAL ESTIMATE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.mutedForeground),
                  ),
                  Text(
                    inr(grandTotal),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            // Cap the button so the total keeps ~110dp on narrow phones /
            // large font scales; the label wraps instead of overflowing.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40 - 110),
              child: ElevatedButton(
                onPressed: _isBooking ? null : _submitCentreBooking,
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
                        'Confirm Admission & Get Pass',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Care Centre Admission',
            subtitle: 'Sanjeevani Elder Care Home · Indiranagar',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/centres');
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Select Room Type
                const Text(
                  '1. Select Room / Bed Category',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                ..._roomOptions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final isSelected = _selectedRoomIdx == idx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedRoomIdx = idx),
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
                              child: Icon(r.icon, color: isSelected ? Colors.white : AppColors.primary, size: 18),
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
                                        child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${inr(r.pricePerDay)} / day', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(r.description, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground, height: 1.3)),
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

                // 2. Select Duration
                const Text(
                  '2. Admission Stay Duration',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _durations.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final d = entry.value;
                    final isSelected = _selectedDurationIdx == idx;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: idx < _durations.length - 1 ? 8 : 0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedDurationIdx = idx),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.secondary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${d.days} Days',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isSelected ? Colors.white : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d.label.split('(').last.replaceAll(')', ''),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white70 : AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 3. Patient Details
                const Text(
                  '3. Patient Information & Medical Summary',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Surface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Patient Full Name', border: OutlineInputBorder(), isDense: true),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), isDense: true),
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
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Medical Condition & Rehab Goals',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Admission Formalities
                const Text(
                  '4. Formalities Required at Centre Desk',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Surface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      _ChecklistLine(title: 'Share Check-In OTP with Centre Receptionist'),
                      _ChecklistLine(title: 'Govt Photo ID Proof (Aadhaar / Passport)'),
                      _ChecklistLine(title: 'Hospital Discharge Summary & Doctor Prescription'),
                      _ChecklistLine(title: 'Signed Facility Care & Consent Agreement'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Bill Breakdown
                const Text(
                  '5. Pricing Breakdown',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Surface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PriceSummaryRow(label: '${room.title} (${duration.days} days)', amount: inr(stayTotal)),
                      const SizedBox(height: 6),
                      _PriceSummaryRow(label: 'Refundable Security Escrow Deposit', amount: inr(refundableDeposit)),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.border)),
                      _PriceSummaryRow(label: 'Total Payable', amount: inr(grandTotal), isBold: true),
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

class _ChecklistLine extends StatelessWidget {
  final String title;

  const _ChecklistLine({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class _PriceSummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;

  const _PriceSummaryRow({required this.label, required this.amount, this.isBold = false});

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

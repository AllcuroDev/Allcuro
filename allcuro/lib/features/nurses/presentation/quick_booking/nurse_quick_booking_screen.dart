import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/content/site_contact.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/care_icon.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/utils/currency.dart';
import '../../../bookings/data/bookings_service.dart';
import '../../../bookings/data/models/booking.dart';
import '../../../location/presentation/location_view_model.dart';
import '../../../bookings/presentation/bookings_view_model.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../auth/presentation/quick_login_sheet.dart';
import '../../../services/data/master_services_catalog.dart';
import '../../../services/data/services_repository.dart';

/// Every nursing service with a price, from the Supabase catalog.
List<MasterServiceItem> _nursingServices() =>
    MasterServicesCatalog.allServices.where((s) => s.isNursing && s.finalPrice != null).toList();

/// The admin's top five (Services catalog → "Quick Book Nurse"), topped up in
/// catalog order when fewer than five are set.
List<MasterServiceItem> _topFive(List<MasterServiceItem> all) {
  final ranked = all.where((s) => s.quickBookRank != null).toList()
    ..sort((a, b) => a.quickBookRank!.compareTo(b.quickBookRank!));
  return [...ranked, ...all.where((s) => s.quickBookRank == null)].take(5).toList();
}

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
  String? _selectedId; // null → the first of the top five
  int _selectedSlotIdx = 0; // Default to Instant
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
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

    final all = _nursingServices();
    if (all.isEmpty) return;
    final patientName = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (patientName.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add the patient\'s name and visit address.')),
      );
      return;
    }
    final selectedService = all.firstWhere((s) => s.id == _selectedId, orElse: () => _topFive(all).first);
    setState(() => _isBooking = true);
    final selectedTiming = _timeSlots[_selectedSlotIdx];

    // No partner is picked here: the care desk assigns a verified nurse and
    // shares their details once confirmed.
    final newBooking = Booking(
      id: newBookingId('NUR'),
      type: BookingType.nurse,
      title: selectedService.name,
      when: selectedTiming,
      status: 'Confirmed',
      amount: selectedService.finalPrice! + 149, // + platform fee
      otp: newVisitOtp(),
      liveStatus: BookingLiveStatus.assigned,
      patientName: patientName,
      patientAge: int.tryParse(_ageController.text.trim()) ?? 0,
      patientGender: _gender,
      address: address,
      locality: ref.read(locationViewModelProvider).currentAddress.locality,
      providerName: kAssignedNurseLabel,
      providerPhone: ref.read(careDeskPhoneProvider),
      providerQualifications: 'Assigned by our care desk',
      condition: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await ref.read(bookingsViewModelProvider.notifier).createBooking(newBooking);

    if (mounted) {
      setState(() => _isBooking = false);
      context.push('/nurse-tracker/${newBooking.id}');
    }
  }

  /// "Other": every nursing service outside the top five, in a sheet.
  void _pickOther(List<MasterServiceItem> others, String selectedId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'All nursing services',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
            for (final s in others)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CareIcon(CareIcons.forItem(s.id, s.iconKey), color: AppColors.primary, size: 22),
                title: Text(s.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                subtitle: s.duration.isEmpty ? null : Text(s.duration, style: const TextStyle(fontSize: 11.5)),
                trailing: Text(inr(s.finalPrice!), style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: s.id == selectedId,
                onTap: () {
                  setState(() => _selectedId = s.id);
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(servicesCatalogProvider); // rebuild once the live catalog lands
    final all = _nursingServices();
    if (all.isEmpty) {
      return AppShell(
        currentPath: '/nurse-quick-booking',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ScreenHeader(
              title: 'Quick Nurse Booking',
              subtitle: 'Loading nursing services…',
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }
    final quick = _topFive(all);
    final selectedService = all.firstWhere((s) => s.id == _selectedId, orElse: () => quick.first);
    final inQuick = quick.any((s) => s.id == selectedService.id);
    final others = all.where((s) => !quick.any((q) => q.id == s.id)).toList();
    final basePrice = selectedService.finalPrice!;
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
                  '1. What do you need?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                  children: [
                    for (final s in quick)
                      _QuickTile(
                        asset: CareIcons.forItem(s.id, s.iconKey),
                        label: s.name,
                        sub: inr(s.finalPrice!),
                        selected: s.id == selectedService.id,
                        onTap: () => setState(() => _selectedId = s.id),
                      ),
                    if (others.isNotEmpty)
                      _QuickTile(
                        asset: CareIcons.seeAll,
                        label: inQuick ? 'Other' : selectedService.name,
                        sub: inQuick ? '${others.length} more' : inr(selectedService.finalPrice!),
                        selected: !inQuick,
                        onTap: () => _pickOther(others, selectedService.id),
                      ),
                  ],
                ),
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
                          hintText: 'Patient\'s full name',
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
                                hintText: 'Age',
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
                      _PriceRow(label: selectedService.name, amount: inr(basePrice)),
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

/// One minimal service tile: round icon, name, price.
class _QuickTile extends StatelessWidget {
  final String asset;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _QuickTile({
    required this.asset,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft.withValues(alpha: 0.45) : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: CareIcon(asset, color: selected ? Colors.white : AppColors.primary, size: 22),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.ink),
                ),
              ),
              Text(sub, style: const TextStyle(fontSize: 10.5, color: AppColors.mutedForeground)),
            ],
          ),
        ),
      ),
    );
  }
}

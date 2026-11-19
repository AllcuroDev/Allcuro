import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/bed_slot.dart';
import '../../data/models/room.dart';
import '../../../auth/presentation/onboarding_view_model.dart';

class AddEditRoomDialog extends ConsumerStatefulWidget {
  const AddEditRoomDialog({super.key});

  @override
  ConsumerState<AddEditRoomDialog> createState() => _AddEditRoomDialogState();
}

class _AddEditRoomDialogState extends ConsumerState<AddEditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _selectedWard = 'Care Wing A';
  int _bedCount = 2;
  final Set<String> _selectedAmenities = {};

  final _wards = [
    'Care Wing A',
    'Care Wing B',
    'Deluxe Private Suite',
    'ICU & High Dependency',
    'Rehabilitation & Physio Ward',
  ];

  final _allAmenities = [
    'AC',
    'Attached Restroom',
    'Nurse Call Bell',
    'Oxygen Support',
    'Cardiac Monitor',
    'Attendant Bed',
    'Hospital Electric Bed',
    'TV & Wi-Fi',
  ];

  @override
  void dispose() {
    _roomNumCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final roomId = 'r-${DateTime.now().millisecondsSinceEpoch}';
    final beds = List.generate(
      _bedCount,
      (i) => BedSlot(
        id: 'b-$roomId-${i + 1}',
        label: 'Bed ${_roomNumCtrl.text.trim()}-${String.fromCharCode(65 + i)}',
        occupied: false,
      ),
    );

    final room = Room(
      id: roomId,
      ward: _selectedWard,
      roomNumber: '${_roomNumCtrl.text.trim()} · ${_selectedWard.split(' ').first}',
      ratePerDay: '₹${_rateCtrl.text.trim()}/day',
      beds: beds,
    );

    ref.read(partnerOnboardingProvider.notifier).addRoom(room);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${room.roomNumber} with $_bedCount beds'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Room & Beds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.mutedForeground),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ward / Section',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedWard,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: _wards
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(w, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedWard = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Room Number / Title',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _roomNumCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Room 204, ICU-03, Deluxe 101',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter room name' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bed Capacity',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              initialValue: _bedCount,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              items: [1, 2, 3, 4, 6]
                                  .map((n) => DropdownMenuItem(
                                        value: n,
                                        child: Text('$n Bed${n > 1 ? 's' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _bedCount = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price Per Day (₹)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _rateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter price' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Amenities Included',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(
                          amenity,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.ink,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primarySoft,
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                        elevation: 0,
                      ),
                      child: const Text('Add Room to Inventory', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

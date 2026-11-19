import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/staff_member.dart';
import '../../../auth/presentation/onboarding_view_model.dart';

class AddEditStaffDialog extends ConsumerStatefulWidget {
  const AddEditStaffDialog({super.key});

  @override
  ConsumerState<AddEditStaffDialog> createState() => _AddEditStaffDialogState();
}

class _AddEditStaffDialogState extends ConsumerState<AddEditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  StaffRoleType _selectedRole = StaffRoleType.gnmNurse;
  String _selectedRatio = '1:4';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _expCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final staff = StaffMember(
      id: 's-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      roleType: _selectedRole,
      qualification:
          '${_selectedRole == StaffRoleType.gnmNurse ? 'GNM' : _selectedRole == StaffRoleType.bscNursing ? 'B.Sc Nursing' : _selectedRole == StaffRoleType.anmNurse ? 'ANM' : _selectedRole == StaffRoleType.criticalCareNurse ? 'Critical Care Specialist' : _selectedRole == StaffRoleType.physiotherapist ? 'B.P.T Physio' : 'Certified Attendant'} · ${_expCtrl.text.trim()} yrs exp',
      experienceYears: int.tryParse(_expCtrl.text.trim()) ?? 0,
      ratio: _selectedRatio,
      shiftRate: double.tryParse(_rateCtrl.text.trim()) ?? 0,
      isCertified: true,
      certificateExpiring: false,
    );

    ref.read(partnerOnboardingProvider.notifier).addStaffMember(staff);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${staff.name} (${staff.roleLabel}) to duty roster'),
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
                        'Add Care Staff & Nurse',
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
                    'Staff Full Name',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Full name as on their certificate',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter staff name' : null,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Role & Qualification',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<StaffRoleType>(
                    initialValue: _selectedRole,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: StaffRoleType.gnmNurse,
                        child: Text('GNM Staff Nurse (General Care)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      DropdownMenuItem(
                        value: StaffRoleType.bscNursing,
                        child: Text('B.Sc Senior Nurse (Post-Op / Critical)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      DropdownMenuItem(
                        value: StaffRoleType.criticalCareNurse,
                        child: Text('Critical Care / ICU Specialist Nurse', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      DropdownMenuItem(
                        value: StaffRoleType.anmNurse,
                        child: Text('ANM Duty Nurse (Vitals & Dressings)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      DropdownMenuItem(
                        value: StaffRoleType.careAttendant,
                        child: Text('Certified Care Attendant (Elderly Help)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      DropdownMenuItem(
                        value: StaffRoleType.physiotherapist,
                        child: Text('Physiotherapy & Rehab Specialist', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedRole = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Experience (Years)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _expCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter years' : null,
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
                              'Staff-to-Patient Ratio',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRatio,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: '1:1', child: Text('1:1 (Dedicated)')),
                                DropdownMenuItem(value: '1:2', child: Text('1:2 (High Care)')),
                                DropdownMenuItem(value: '1:3', child: Text('1:3 (Standard)')),
                                DropdownMenuItem(value: '1:4', child: Text('1:4 (Assisted)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedRatio = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Shift Rate / Service Package (₹)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: 'e.g. 1800 per 12h shift',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter shift rate' : null,
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
                      child: const Text('Add Staff to Roster', style: TextStyle(fontWeight: FontWeight.w800)),
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

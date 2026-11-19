import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/ui/tappable.dart';
import '../../data/models/equipment_item.dart';
import '../../../auth/presentation/onboarding_view_model.dart';

class EquipmentManagementScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const EquipmentManagementScreen({super.key, required this.onBack});

  void _showAddEquipmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddEquipmentDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerOnboardingProvider);
    final equipmentList = state.equipmentList;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Medical Equipment & Rentals',
              subtitle: 'Rent ICU beds, oxygen concentrators & mobility devices to patients',
              onBack: onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Surface(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${equipmentList.length} Equipment Items Listed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Security deposits are held in escrow and settled automatically upon device return.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your equipment catalog',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Tappable(
                        onTap: () => _showAddEquipmentDialog(context),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Add item',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (equipmentList.isEmpty)
                    Surface(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.mutedForeground),
                          const SizedBox(height: 12),
                          const Text(
                            'No medical equipment listed yet',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add oxygen concentrators, hospital beds, or wheelchairs to earn additional revenue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEquipmentDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add First Equipment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.accentForeground,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...equipmentList.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EquipmentCard(
                          item: item,
                          onDelete: () {
                            ref.read(partnerOnboardingProvider.notifier).removeEquipmentItem(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Removed ${item.title}')),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Material(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: () => _showAddEquipmentDialog(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Add more equipment & devices',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  final VoidCallback onDelete;

  const _EquipmentCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.category == EquipmentCategory.respiratory
                      ? Icons.air_rounded
                      : item.category == EquipmentCategory.hospitalBeds
                          ? Icons.single_bed_rounded
                          : item.category == EquipmentCategory.mobility
                              ? Icons.accessible_rounded
                              : Icons.monitor_heart_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.categoryLabel} · ${item.conditionLabel}',
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.mutedForeground),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (item.specifications.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.specifications,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, height: 1.3),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(child: _RateCol(label: 'Daily Rate', value: '₹${item.dailyRate.toInt()}/d')),
                Expanded(child: _RateCol(label: 'Monthly', value: '₹${item.monthlyRate.toInt()}/mo')),
                Expanded(child: _RateCol(label: 'Deposit', value: '₹${item.depositAmount.toInt()}')),
                Expanded(child: _RateCol(label: 'Stock', value: '${item.stockQuantity} pcs')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateCol extends StatelessWidget {
  final String label;
  final String value;

  const _RateCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ],
    );
  }
}

class _AddEquipmentDialog extends ConsumerStatefulWidget {
  const _AddEquipmentDialog();

  @override
  ConsumerState<_AddEquipmentDialog> createState() => _AddEquipmentDialogState();
}

class _AddEquipmentDialogState extends ConsumerState<_AddEquipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _dailyRateCtrl = TextEditingController();
  final _monthlyRateCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _specsCtrl = TextEditingController();
  EquipmentCategory _selectedCategory = EquipmentCategory.respiratory;
  EquipmentCondition _selectedCondition = EquipmentCondition.brandNew;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dailyRateCtrl.dispose();
    _monthlyRateCtrl.dispose();
    _depositCtrl.dispose();
    _stockCtrl.dispose();
    _specsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final item = EquipmentItem(
      id: 'eq-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      category: _selectedCategory,
      condition: _selectedCondition,
      dailyRate: double.tryParse(_dailyRateCtrl.text.trim()) ?? 0,
      monthlyRate: double.tryParse(_monthlyRateCtrl.text.trim()) ?? 0,
      depositAmount: double.tryParse(_depositCtrl.text.trim()) ?? 0,
      stockQuantity: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      specifications: _specsCtrl.text.trim(),
    );

    ref.read(partnerOnboardingProvider.notifier).addEquipmentItem(item);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item.title} to equipment rentals'),
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
                        'Add Medical Equipment',
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
                    'Equipment Title / Model',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Philips 10L Oxygen Concentrator',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter equipment title' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<EquipmentCategory>(
                              initialValue: _selectedCategory,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: EquipmentCategory.respiratory, child: Text('Respiratory', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: EquipmentCategory.hospitalBeds, child: Text('Hospital Beds', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: EquipmentCategory.mobility, child: Text('Mobility / Wheelchairs', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: EquipmentCategory.icuMonitoring, child: Text('ICU Monitoring', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: EquipmentCategory.physiotherapy, child: Text('Physiotherapy', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCategory = v);
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
                              'Condition',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<EquipmentCondition>(
                              initialValue: _selectedCondition,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: EquipmentCondition.brandNew, child: Text('Brand New', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: EquipmentCondition.refurbishedGradeA, child: Text('Refurbished - Grade A', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: EquipmentCondition.refurbishedGradeB, child: Text('Refurbished - Grade B', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCondition = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Rate (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _dailyRateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Rate (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _monthlyRateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Deposit (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _depositCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Specifications / Features', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedForeground)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _specsCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. 10 LPM continuous flow, purity 93%, includes humidifier bottle',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
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
                      child: const Text('Save & Add to Catalog', style: TextStyle(fontWeight: FontWeight.w800)),
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

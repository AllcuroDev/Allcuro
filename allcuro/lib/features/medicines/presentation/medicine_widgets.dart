import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../data/medicine.dart';
import 'medicine_cart_view_model.dart';
import 'prescription_picker.dart';

/// Pill glyph tile for a medicine row.
class MedicineThumb extends StatelessWidget {
  final Medicine medicine;
  final double size;

  const MedicineThumb({super.key, required this.medicine, this.size = 52});

  IconData get _icon {
    final p = medicine.pack.toLowerCase();
    if (p.contains('bottle') && p.contains('ml')) return Icons.local_drink_outlined;
    if (p.contains('sachet')) return Icons.inventory_2_outlined;
    return Icons.medication_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: medicine.rx ? const Color(0xFFF2EDFE) : const Color(0xFFE7F4EB),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        _icon,
        size: size * 0.5,
        color: medicine.rx ? const Color(0xFF6D28D9) : AppColors.primary,
      ),
    );
  }
}

class RxBadge extends StatelessWidget {
  const RxBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDFE),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: const Color(0xFFDDD0FB)),
      ),
      child: const Text(
        'Rx',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6D28D9)),
      ),
    );
  }
}

/// "Add" button that turns into a − qty + stepper once the item is in the cart.
class QtyStepper extends StatelessWidget {
  final String label;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const QtyStepper({
    super.key,
    required this.label,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return Semantics(
        button: true,
        label: 'Add $label to cart',
        excludeSemantics: true,
        child: OutlinedButton(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.2),
            minimumSize: const Size(76, 38),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          child: const Text('ADD'),
        ),
      );
    }
    final atMax = qty >= MedicinePricing.maxQty;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, tooltip: 'Remove one $label', onTap: onRemove),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 22),
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              semanticsLabel: '$qty in cart',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: atMax ? 'Maximum ${MedicinePricing.maxQty}' : 'Add one more $label',
            onTap: atMax ? null : onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(
          width: 34,
          height: 38,
          child: Icon(icon, size: 18, color: onTap == null ? Colors.white54 : Colors.white),
        ),
      ),
    );
  }
}

/// One medicine: thumb, name, pack, price with MRP and the cart stepper.
class MedicineRow extends ConsumerWidget {
  final Medicine medicine;
  final bool fromPrescription;

  const MedicineRow({super.key, required this.medicine, this.fromPrescription = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(medicineCartProvider.select((s) => s.qtyOf(medicine.id)));
    final cart = ref.read(medicineCartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedicineThumb(medicine: medicine),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.25, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(medicine.pack, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                    if (medicine.rx) const RxBadge(),
                    if (fromPrescription)
                      const Text(
                        'From your prescription',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(
                            inr(medicine.price),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink),
                          ),
                          if (medicine.mrp > medicine.price) ...[
                            Text(
                              inr(medicine.mrp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              '${medicine.discountPercent}% off',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    QtyStepper(
                      label: medicine.name,
                      qty: qty,
                      onAdd: () => cart.add(medicine),
                      onRemove: () => cart.remove(medicine),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Prescription status card: upload prompt → pharmacist reviewing → attached.
class PrescriptionCard extends ConsumerWidget {
  /// Shown above the upload button when Rx medicines are waiting on it.
  final bool isRequired;

  const PrescriptionCard({super.key, this.isRequired = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(medicineCartProvider);
    final file = cart.prescription;

    if (file == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRequired ? const Color(0xFFFFF7ED) : const Color(0xFFF2FAF5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isRequired ? const Color(0xFFFED7AA) : AppColors.primarySoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isRequired ? Icons.error_outline_rounded : Icons.description_outlined,
                  color: isRequired ? AppColors.warning : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRequired ? 'Prescription needed' : 'Have a prescription?',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRequired
                            ? 'Upload a prescription to order Rx medicines. A licensed pharmacist checks it before dispatch.'
                            : 'Upload it and our pharmacist adds the medicines to your cart with the total.',
                        style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => pickPrescription(context, ref),
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text('Upload prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(46),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
          ],
        ),
      );
    }

    final reviewing = cart.prescriptionStatus == PrescriptionStatus.reviewing;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: file.previewBytes != null
                      ? Image.memory(file.previewBytes!, fit: BoxFit.cover, cacheWidth: 160)
                      : const ColoredBox(
                          color: Color(0xFFFDECEC),
                          child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.destructive),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reviewing ? '${file.sizeLabel} · Pharmacist is reading it…' : '${file.sizeLabel} · Medicines added to cart',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: reviewing ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove prescription',
                onPressed: () => ref.read(medicineCartProvider.notifier).removePrescription(),
                icon: const Icon(Icons.close_rounded, color: AppColors.mutedForeground),
              ),
            ],
          ),
          if (reviewing) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => pickPrescription(context, ref),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Replace'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Item total → savings → delivery → total, used in the cart.
class MedicineBill extends StatelessWidget {
  final MedicineCartState cart;

  const MedicineBill({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'BILL SUMMARY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          _BillRow(label: 'Item total (MRP)', value: inr(cart.mrpTotal)),
          if (cart.savings > 0) _BillRow(label: 'Discount', value: '− ${inr(cart.savings)}', valueColor: AppColors.success),
          _BillRow(
            label: 'Delivery fee',
            value: cart.deliveryFee == 0 ? 'FREE' : inr(cart.deliveryFee),
            valueColor: cart.deliveryFee == 0 ? AppColors.success : null,
          ),
          if (cart.toFreeDelivery > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Add ${inr(cart.toFreeDelivery)} more for free delivery',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.warning),
              ),
            ),
          const Divider(height: 16, color: AppColors.border),
          Row(
            children: [
              const Expanded(
                child: Text('To pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              Text(inr(cart.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ],
          ),
          if (cart.savings > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'You save ${inr(cart.savings)} on this order',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Prices include GST. Rx medicines are dispatched only after a licensed pharmacist verifies your prescription.',
            style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BillRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.mutedForeground))),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.ink),
          ),
        ],
      ),
    );
  }
}

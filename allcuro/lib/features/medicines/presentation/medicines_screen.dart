import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/utils/currency.dart';
import '../data/medicine.dart';
import 'medicine_cart_view_model.dart';
import 'medicine_widgets.dart';
import 'prescription_picker.dart';

const _saffron = Color(0xFFEE6D01);
const _saffronDeep = Color(0xFFC85A00);
const _saffronWash = Color(0xFFFFF3E6);

/// Order Medicines: search & add to cart, or upload a prescription.
/// `/medicines?upload=1` opens the prescription picker straight away.
class MedicinesScreen extends ConsumerStatefulWidget {
  final bool openUpload;

  const MedicinesScreen({super.key, this.openUpload = false});

  @override
  ConsumerState<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends ConsumerState<MedicinesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.openUpload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) pickPrescription(context, ref);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(medicineCartProvider);
    final results = MedicineCatalog.search(_query, category: _category);
    final chipHeight = MediaQuery.textScalerOf(context).scale(13) * 1.3 + 18;

    return AppShell(
      currentPath: '/medicines',
      bottomBar: cart.lines.isEmpty ? null : _CartBar(cart: cart),
      child: ColoredBox(
        color: const Color(0xFFF7F8F7),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _TopBar(
              cartCount: cart.itemCount,
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
              onCart: () => context.push('/medicines/cart'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search medicines',
                  hintStyle: const TextStyle(fontSize: 14.5, color: AppColors.mutedForeground),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedForeground),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _PrescriptionStrip(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: chipHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: MedicineCatalog.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = MedicineCatalog.categories[i];
                  final selected = c == _category;
                  return Material(
                    color: selected ? AppColors.ink : Colors.white,
                    shape: StadiumBorder(
                      side: BorderSide(color: selected ? AppColors.ink : AppColors.border),
                    ),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => setState(() => _category = c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            if (results.isEmpty)
              _NoResults(query: _query)
            else
              for (final m in results)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _MedicineCard(medicine: m),
                ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int cartCount;
  final VoidCallback onBack;
  final VoidCallback onCart;

  const _TopBar({required this.cartCount, required this.onBack, required this.onCart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: 2),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicines',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppColors.ink),
                ),
                Text(
                  'Delivered today · Licensed pharmacies',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Cart',
                onPressed: onCart,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.ink),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _saffron,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(fontSize: 10, height: 1, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One slim row: upload prompt → pharmacist reading → attached.
class _PrescriptionStrip extends ConsumerWidget {
  const _PrescriptionStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(medicineCartProvider);
    final file = cart.prescription;
    final reviewing = cart.prescriptionStatus == PrescriptionStatus.reviewing;

    final Widget leading;
    final String title;
    final String subtitle;
    Widget? trailing;
    VoidCallback? onTap;

    if (file == null) {
      leading = const Icon(Icons.receipt_long_rounded, color: _saffron, size: 20);
      title = 'Have a prescription?';
      subtitle = 'We\'ll add the medicines for you';
      onTap = () => pickPrescription(context, ref);
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: _saffron, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: const Text(
          'Upload',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
    } else if (reviewing) {
      leading = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: _saffron),
      );
      title = 'Pharmacist is reading it…';
      subtitle = file.name;
    } else {
      leading = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
      title = 'Prescription added';
      subtitle = 'Medicines are in your cart · ${file.name}';
      trailing = IconButton(
        tooltip: 'Remove prescription',
        visualDensity: VisualDensity.compact,
        onPressed: () => ref.read(medicineCartProvider.notifier).removePrescription(),
        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.mutedForeground),
      );
    }

    return Material(
      color: file == null ? _saffronWash : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: file == null ? const Color(0xFFFFD8B3) : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: leading,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: file == null ? const Color(0xFF7C2D12) : AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: file == null ? _saffronDeep : AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineCard extends ConsumerWidget {
  final Medicine medicine;

  const _MedicineCard({required this.medicine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(medicineCartProvider.select((s) => s.qtyOf(medicine.id)));
    final cart = ref.read(medicineCartProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: qty > 0 ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedicineThumb(medicine: medicine, size: 56),
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
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            inr(medicine.price),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.successSoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '${medicine.discountPercent}% off',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
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

class _NoResults extends ConsumerWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 40, color: AppColors.mutedForeground),
          const SizedBox(height: 10),
          Text(
            query.trim().isEmpty ? 'No medicines in this category yet' : 'No results for "${query.trim()}"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            "Can't find it? Upload your prescription and our pharmacist will add it.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => pickPrescription(context, ref),
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Upload prescription', style: TextStyle(fontWeight: FontWeight.w800)),
            style: TextButton.styleFrom(foregroundColor: _saffronDeep),
          ),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final MedicineCartState cart;

  const _CartBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push('/medicines/cart'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} · ${inr(cart.total)}',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      Text(
                        cart.toFreeDelivery > 0
                            ? 'Add ${inr(cart.toFreeDelivery)} for free delivery'
                            : 'Free delivery unlocked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFD1FAE5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'View cart',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

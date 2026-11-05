import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/screen_header.dart';
import '../../../core/utils/currency.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../auth/presentation/quick_login_sheet.dart';
import '../../bookings/data/models/booking.dart';
import '../../bookings/presentation/bookings_view_model.dart';
import '../../location/presentation/location_sheet.dart';
import '../../location/presentation/location_view_model.dart';
import 'medicine_cart_view_model.dart';
import 'medicine_widgets.dart';

enum _PayMethod { upi, card, cod }

extension on _PayMethod {
  String get label => switch (this) {
        _PayMethod.upi => 'UPI',
        _PayMethod.card => 'Credit / Debit card',
        _PayMethod.cod => 'Cash on delivery',
      };

  IconData get icon => switch (this) {
        _PayMethod.upi => Icons.qr_code_2_rounded,
        _PayMethod.card => Icons.credit_card_rounded,
        _PayMethod.cod => Icons.payments_outlined,
      };
}

class MedicineCartScreen extends ConsumerStatefulWidget {
  const MedicineCartScreen({super.key});

  @override
  ConsumerState<MedicineCartScreen> createState() => _MedicineCartScreenState();
}

class _MedicineCartScreenState extends ConsumerState<MedicineCartScreen> {
  bool _placing = false;

  void _checkout() {
    final auth = ref.read(authViewModelProvider);
    final signedIn = auth.status == AuthStatus.onboarded || auth.status == AuthStatus.authenticated;
    if (signedIn) {
      _choosePayment();
    } else {
      QuickLoginSheet.show(
        context,
        title: 'Login to place your order',
        subtitle: 'Verify your mobile number so we can deliver your medicines',
        onSuccess: _choosePayment,
      );
    }
  }

  Future<void> _choosePayment() async {
    final total = ref.read(medicineCartProvider).total;
    final method = await showModalBottomSheet<_PayMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(total: total),
    );
    if (method != null && mounted) await _placeOrder(method);
  }

  Future<void> _placeOrder(_PayMethod method) async {
    setState(() => _placing = true);
    // Simulated gateway, like the rest of the demo checkout.
    await Future.delayed(const Duration(milliseconds: 900));

    final cart = ref.read(medicineCartProvider);
    final address = ref.read(locationViewModelProvider).currentAddress;
    final auth = ref.read(authViewModelProvider);
    final rng = Random();
    final id = 'ALC-MED-${10000 + rng.nextInt(90000)}';

    final booking = Booking(
      id: id,
      type: BookingType.medicine,
      title: 'Medicine order · ${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
      when: 'Delivery today, within 3 hrs',
      status: 'Confirmed',
      amount: cart.total,
      otp: '${1000 + rng.nextInt(9000)}',
      liveStatus: BookingLiveStatus.assigned,
      patientName: auth.userProfile['name'] ?? 'Customer',
      address: address.fullAddress,
      locality: address.shortAddress,
      providerName: 'ALLCURO Partner Pharmacy',
      providerPhone: '+91 80 4120 5500',
      providerQualifications: 'Licensed pharmacy · ${method.label}',
      vitalsSummary: null,
      condition: null,
      formalities: const [],
      items: [
        for (final l in cart.lines) '${l.medicine.name} × ${l.qty} · ${inr(l.total)}',
      ],
      prescriptionName: cart.prescription?.name,
    );

    await ref.read(bookingsViewModelProvider.notifier).createBooking(booking);
    ref.read(medicineCartProvider.notifier).clear();
    if (!mounted) return;
    setState(() => _placing = false);
    context.pushReplacement('/medicine-order/$id');
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(medicineCartProvider);
    final address = ref.watch(locationViewModelProvider).currentAddress;
    final reviewing = cart.prescriptionStatus == PrescriptionStatus.reviewing;

    return AppShell(
      currentPath: '/medicines/cart',
      bottomBar: cart.lines.isEmpty && !reviewing
          ? null
          : _PayBar(
              total: cart.total,
              enabled: cart.canCheckout && !_placing,
              busy: _placing,
              hint: reviewing
                  ? 'Waiting for the pharmacist…'
                  : cart.needsPrescription
                      ? 'Upload a prescription to order Rx medicines'
                      : null,
              onPay: _checkout,
            ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          ScreenHeader(
            title: 'Your cart',
            subtitle: cart.lines.isEmpty ? 'Nothing added yet' : '${cart.itemCount} items · delivered today',
            onBack: () => context.canPop() ? context.pop() : context.go('/medicines'),
          ),
          if (cart.lines.isEmpty && !reviewing)
            _EmptyCart(onBrowse: () => context.canPop() ? context.pop() : context.go('/medicines'))
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (int i = 0; i < cart.lines.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    MedicineRow(
                      medicine: cart.lines[i].medicine,
                      fromPrescription: cart.lines[i].fromPrescription,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/medicines'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add more medicines'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const _SectionTitle('Prescription'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PrescriptionCard(isRequired: cart.needsPrescription),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Deliver to'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address.fullAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, height: 1.35, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => LocationSheet.show(context),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      child: const Text('Change', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (cart.lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MedicineBill(cart: cart),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptyCart({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.mutedForeground),
          const SizedBox(height: 12),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search for medicines or upload a prescription.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onBrowse,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            child: const Text('Browse medicines', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  final int total;
  final bool enabled;
  final bool busy;
  final String? hint;
  final VoidCallback onPay;

  const _PayBar({
    required this.total,
    required this.enabled,
    required this.busy,
    required this.hint,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TO PAY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.mutedForeground),
                    ),
                    Text(
                      inr(total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ElevatedButton(
                  onPressed: enabled ? onPay : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.mutedForeground,
                    elevation: 0,
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Place order',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

class _PaymentSheet extends StatefulWidget {
  final int total;

  const _PaymentSheet({required this.total});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  _PayMethod _method = _PayMethod.upi;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const Text(
                'Choose payment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              const Text(
                'Demo checkout — no money is charged.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 14),
              RadioGroup<_PayMethod>(
                groupValue: _method,
                onChanged: (m) => setState(() => _method = m ?? _method),
                child: Column(
                  children: [
                    for (final m in _PayMethod.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: m == _method ? AppColors.primarySoft : AppColors.secondary,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: RadioListTile<_PayMethod>(
                            value: m,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                            secondary: Icon(m.icon, color: AppColors.primary),
                            title: Text(
                              m.label,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _method),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                ),
                child: Text(
                  _method == _PayMethod.cod ? 'Place order · ${inr(widget.total)}' : 'Pay ${inr(widget.total)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

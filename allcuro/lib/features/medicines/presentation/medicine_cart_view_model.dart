import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/medicine.dart';

@immutable
class CartLine {
  final Medicine medicine;
  final int qty;

  /// Marked by the pharmacist as coming from the prescription (set by the
  /// pharmacy once a backend exists; the app itself never adds lines).
  final bool fromPrescription;

  const CartLine({required this.medicine, required this.qty, this.fromPrescription = false});

  int get total => medicine.price * qty;
  int get mrpTotal => medicine.mrp * qty;

  CartLine copyWith({int? qty, bool? fromPrescription}) => CartLine(
        medicine: medicine,
        qty: qty ?? this.qty,
        fromPrescription: fromPrescription ?? this.fromPrescription,
      );
}

@immutable
class PrescriptionFile {
  final String name;
  final int sizeBytes;
  final bool isPdf;

  /// Image bytes for the thumbnail; null for PDFs.
  final Uint8List? previewBytes;

  const PrescriptionFile({
    required this.name,
    required this.sizeBytes,
    required this.isPdf,
    this.previewBytes,
  });

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / 1024).ceil()} KB';
  }
}

/// [attached]: the file goes with the order; a licensed pharmacist reviews it
/// and calls the customer to confirm the medicines.
enum PrescriptionStatus { none, attached }

@immutable
class MedicineCartState {
  final List<CartLine> lines;
  final PrescriptionFile? prescription;
  final PrescriptionStatus prescriptionStatus;

  const MedicineCartState({
    this.lines = const [],
    this.prescription,
    this.prescriptionStatus = PrescriptionStatus.none,
  });

  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);
  int get itemTotal => lines.fold(0, (sum, l) => sum + l.total);
  int get mrpTotal => lines.fold(0, (sum, l) => sum + l.mrpTotal);
  int get savings => mrpTotal - itemTotal;
  int get deliveryFee =>
      lines.isEmpty || itemTotal >= MedicinePricing.freeDeliveryFrom ? 0 : MedicinePricing.deliveryFee;
  int get total => itemTotal + deliveryFee;

  /// Amount still to add for free delivery (0 once reached).
  int get toFreeDelivery =>
      itemTotal >= MedicinePricing.freeDeliveryFrom ? 0 : MedicinePricing.freeDeliveryFrom - itemTotal;

  bool get hasRxItems => lines.any((l) => l.medicine.rx);

  /// Rx medicines can only be ordered against a prescription.
  bool get needsPrescription => hasRxItems && prescription == null;

  /// A prescription alone is a valid order: the pharmacist prices it and calls.
  bool get isPrescriptionOnly => lines.isEmpty && prescription != null;

  bool get canCheckout => (lines.isNotEmpty || prescription != null) && !needsPrescription;

  int qtyOf(String medicineId) {
    for (final l in lines) {
      if (l.medicine.id == medicineId) return l.qty;
    }
    return 0;
  }

  MedicineCartState copyWith({
    List<CartLine>? lines,
    PrescriptionFile? prescription,
    bool clearPrescription = false,
    PrescriptionStatus? prescriptionStatus,
  }) {
    return MedicineCartState(
      lines: lines ?? this.lines,
      prescription: clearPrescription ? null : (prescription ?? this.prescription),
      prescriptionStatus: prescriptionStatus ?? this.prescriptionStatus,
    );
  }
}

/// Medicine cart for the session. A prescription is only attached here — it
/// never adds medicines on its own; the pharmacist reviews it after the order
/// is placed and calls the customer.
class MedicineCartViewModel extends Notifier<MedicineCartState> {
  @override
  MedicineCartState build() => const MedicineCartState();

  void setQty(Medicine medicine, int qty) {
    final clamped = qty.clamp(0, MedicinePricing.maxQty);
    final lines = [...state.lines];
    final i = lines.indexWhere((l) => l.medicine.id == medicine.id);
    if (clamped == 0) {
      if (i >= 0) lines.removeAt(i);
    } else if (i >= 0) {
      lines[i] = lines[i].copyWith(qty: clamped);
    } else {
      lines.add(CartLine(medicine: medicine, qty: clamped));
    }
    state = state.copyWith(lines: lines);
  }

  void add(Medicine medicine) => setQty(medicine, state.qtyOf(medicine.id) + 1);
  void remove(Medicine medicine) => setQty(medicine, state.qtyOf(medicine.id) - 1);

  /// Attaches (or replaces) the prescription sent with the order.
  void attachPrescription(PrescriptionFile file) {
    state = state.copyWith(prescription: file, prescriptionStatus: PrescriptionStatus.attached);
  }

  void removePrescription() {
    state = state.copyWith(clearPrescription: true, prescriptionStatus: PrescriptionStatus.none);
  }

  void clear() => state = const MedicineCartState();
}

final medicineCartProvider =
    NotifierProvider<MedicineCartViewModel, MedicineCartState>(MedicineCartViewModel.new);

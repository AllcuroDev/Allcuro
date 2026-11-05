import 'package:flutter/foundation.dart';

/// A medicine sold through ALLCURO's partner pharmacy. Prices are in rupees
/// and GST-inclusive. Mirrors `allcuro_web/src/data/medicines.ts` — keep the
/// ids, prices and Rx flags identical on both.
@immutable
class Medicine {
  final String id;
  final String name;
  final String pack;
  final int mrp;
  final int price;

  /// Prescription-only: ordering it needs an uploaded prescription.
  final bool rx;
  final String category;

  const Medicine({
    required this.id,
    required this.name,
    required this.pack,
    required this.mrp,
    required this.price,
    required this.rx,
    required this.category,
  });

  int get discountPercent => mrp <= 0 ? 0 : (((mrp - price) / mrp) * 100).round();
}

class MedicineCatalog {
  MedicineCatalog._();

  static const categories = [
    'All',
    'Fever & Pain',
    'Cold & Allergy',
    'Stomach Care',
    'Diabetes & Thyroid',
    'BP & Heart',
    'Antibiotics',
    'Vitamins',
  ];

  static const all = <Medicine>[
    Medicine(id: 'paracetamol-650', name: 'Paracetamol 650 mg Tablet', pack: 'Strip of 15 tablets', mrp: 34, price: 30, rx: false, category: 'Fever & Pain'),
    Medicine(id: 'ibuprofen-400', name: 'Ibuprofen 400 mg Tablet', pack: 'Strip of 15 tablets', mrp: 42, price: 36, rx: false, category: 'Fever & Pain'),
    Medicine(id: 'cetirizine-10', name: 'Cetirizine 10 mg Tablet', pack: 'Strip of 10 tablets', mrp: 22, price: 19, rx: false, category: 'Cold & Allergy'),
    Medicine(id: 'cough-syrup', name: 'Ambroxol Cough Syrup', pack: 'Bottle of 100 ml', mrp: 115, price: 98, rx: false, category: 'Cold & Allergy'),
    Medicine(id: 'ors-orange', name: 'ORS Electrolyte Powder (Orange)', pack: 'Pack of 5 sachets', mrp: 110, price: 99, rx: false, category: 'Stomach Care'),
    Medicine(id: 'antacid-gel', name: 'Antacid Gel (Mint)', pack: 'Bottle of 170 ml', mrp: 129, price: 110, rx: false, category: 'Stomach Care'),
    Medicine(id: 'pantoprazole-40', name: 'Pantoprazole 40 mg Tablet', pack: 'Strip of 15 tablets', mrp: 155, price: 132, rx: true, category: 'Stomach Care'),
    Medicine(id: 'metformin-500', name: 'Metformin 500 mg SR Tablet', pack: 'Strip of 20 tablets', mrp: 48, price: 41, rx: true, category: 'Diabetes & Thyroid'),
    Medicine(id: 'glimepiride-1', name: 'Glimepiride 1 mg Tablet', pack: 'Strip of 10 tablets', mrp: 92, price: 78, rx: true, category: 'Diabetes & Thyroid'),
    Medicine(id: 'thyroxine-50', name: 'Thyroxine 50 mcg Tablet', pack: 'Bottle of 100 tablets', mrp: 180, price: 153, rx: true, category: 'Diabetes & Thyroid'),
    Medicine(id: 'amlodipine-5', name: 'Amlodipine 5 mg Tablet', pack: 'Strip of 15 tablets', mrp: 64, price: 55, rx: true, category: 'BP & Heart'),
    Medicine(id: 'telmisartan-40', name: 'Telmisartan 40 mg Tablet', pack: 'Strip of 15 tablets', mrp: 118, price: 99, rx: true, category: 'BP & Heart'),
    Medicine(id: 'atorvastatin-10', name: 'Atorvastatin 10 mg Tablet', pack: 'Strip of 15 tablets', mrp: 140, price: 119, rx: true, category: 'BP & Heart'),
    Medicine(id: 'amoxicillin-500', name: 'Amoxicillin 500 mg Capsule', pack: 'Strip of 10 capsules', mrp: 98, price: 84, rx: true, category: 'Antibiotics'),
    Medicine(id: 'azithromycin-500', name: 'Azithromycin 500 mg Tablet', pack: 'Strip of 3 tablets', mrp: 119, price: 101, rx: true, category: 'Antibiotics'),
    Medicine(id: 'vitamin-d3', name: 'Vitamin D3 60,000 IU Capsule', pack: 'Strip of 4 capsules', mrp: 136, price: 115, rx: false, category: 'Vitamins'),
    Medicine(id: 'calcium-d3', name: 'Calcium + Vitamin D3 Tablet', pack: 'Strip of 15 tablets', mrp: 125, price: 106, rx: false, category: 'Vitamins'),
    Medicine(id: 'multivitamin', name: 'Multivitamin Tablet', pack: 'Bottle of 30 tablets', mrp: 320, price: 272, rx: false, category: 'Vitamins'),
  ];

  /// What the (simulated) pharmacist reads off an uploaded prescription.
  /// Replace with the pharmacy partner's response once a backend exists.
  static const prescriptionDemoItems = <String, int>{
    'metformin-500': 2,
    'amlodipine-5': 1,
    'pantoprazole-40': 1,
  };

  static Medicine? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  static List<Medicine> search(String query, {String category = 'All'}) {
    final q = query.trim().toLowerCase();
    return all.where((m) {
      if (category != 'All' && m.category != category) return false;
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q) ||
          m.pack.toLowerCase().contains(q);
    }).toList();
  }
}

/// Pricing rules shared with the website: free delivery from ₹499,
/// otherwise a ₹39 fee. Medicine prices already include GST.
class MedicinePricing {
  MedicinePricing._();

  static const freeDeliveryFrom = 499;
  static const deliveryFee = 39;
  static const maxQty = 10;
}

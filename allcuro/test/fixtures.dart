// Test-only fixtures shaped like Supabase rows. The app itself ships no
// partner, equipment, medicine or booking data — these exist so tests can
// exercise populated screens alongside the empty states.

import 'package:allcuro/features/bookings/data/bookings_repository.dart';
import 'package:allcuro/features/bookings/data/bookings_service.dart';
import 'package:allcuro/features/bookings/data/models/booking.dart';
import 'package:allcuro/features/equipment/data/equipment_repository.dart';
import 'package:allcuro/features/equipment/data/equipment_service.dart';
import 'package:allcuro/features/equipment/data/models/equipment.dart';
import 'package:allcuro/features/medicines/data/medicine.dart';
import 'package:allcuro/features/partners/data/partners_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const testNurseRow = <String, dynamic>{
  'id': '00000000-0000-0000-0000-000000000001',
  'slug': 'test-nurse',
  'kind': 'nurse',
  'allcuro_code': 'AC-N-00001',
  'display_name': 'Test Nurse',
  'photo_url': null,
  'headline': 'GNM Diploma',
  'bio': 'Fixture nurse used by widget tests.',
  'city': 'Test City',
  'locality': 'Test Locality',
  'languages': ['English'],
  'skills': ['Wound Dressing', 'Injections & IV'],
  'highlights': ['Fixture highlight'],
  'qualification': 'GNM',
  'specialisations': ['Elderly Care'],
  'experience_years': 5,
  'employment_type': 'Part-time',
  'is_available': true,
  'rating': null,
  'review_count': 0,
};

const testCaregiverRow = <String, dynamic>{
  'id': '00000000-0000-0000-0000-000000000002',
  'slug': 'test-caregiver',
  'kind': 'caregiver',
  'display_name': 'Test Caregiver',
  'headline': '',
  'qualification': 'GDA',
  'city': 'Test City',
  'locality': '',
  'languages': <String>[],
  'skills': <String>[],
  'highlights': <String>[],
  'specialisations': <String>[],
  'experience_years': 0,
  'employment_type': 'Full-time',
  'is_available': false,
  'rating': 4.5,
  'review_count': 12,
};

const testCentreRow = <String, dynamic>{
  'id': '00000000-0000-0000-0000-000000000003',
  'slug': 'test-centre',
  'kind': 'centre',
  'display_name': 'Test Care Centre',
  'photo_url': null,
  'headline': 'Elderly care',
  'centre_type': 'Rehab & recovery',
  'bio': 'Fixture centre used by widget tests.',
  'city': 'Test City',
  'locality': 'Test Locality',
  'year_established': 2019,
  'staff_ratio': '1 : 4',
  'beds_available': 2,
  'services_included': ['24/7 Nursing', 'Physiotherapy'],
  'room_types': ['Shared room', 'Private room'],
  'photos': <String>[],
  'licence_no': 'TEST-LIC-1',
  'public_phone': '',
  'price_per_day': 2000,
  'price_per_month': 50000,
  'discount_percent': 10,
  'rating': null,
  'review_count': 0,
};

const testOfferingRows = <Map<String, dynamic>>[
  {
    'id': 'o1',
    'partner_id': '00000000-0000-0000-0000-000000000001',
    'service_id': 'wound-dressing',
    'label': 'Wound dressing visit',
    'unit': 'per visit',
    'price': 700,
    'discount_percent': 10,
    'final_price': 630,
  },
];

const testEquipmentRow = <String, dynamic>{
  'id': 'e1',
  'slug': 'test-wheelchair',
  'title': 'Test Wheelchair',
  'category': 'Mobility',
  'condition': 'New',
  'description': '',
  'features': <String>[],
  'daily_rate': 100,
  'monthly_rate': 2000,
  'deposit_amount': 1000,
  'discount_percent': 10,
  'stock_quantity': 3,
  'photo_url': null,
  'available_pincodes': '',
  'is_available': true,
};

const testMedicines = <Medicine>[
  Medicine(id: 'test-pain-650', name: 'Test Pain Relief 650 mg', pack: 'Strip of 15 tablets', mrp: 34, price: 30, rx: false, category: 'Fever & Pain'),
  Medicine(id: 'test-allergy-10', name: 'Test Allergy 10 mg', pack: 'Strip of 10 tablets', mrp: 22, price: 19, rx: false, category: 'Cold & Allergy'),
  Medicine(id: 'test-ors', name: 'Test ORS Powder', pack: 'Pack of 5 sachets', mrp: 110, price: 99, rx: false, category: 'Stomach Care'),
  Medicine(id: 'test-rx-antibiotic', name: 'Test Antibiotic 500 mg', pack: 'Strip of 3 tablets', mrp: 119, price: 101, rx: true, category: 'Antibiotics'),
  Medicine(id: 'test-rx-bp', name: 'Test BP 5 mg', pack: 'Strip of 15 tablets', mrp: 64, price: 55, rx: true, category: 'BP & Heart'),
  Medicine(id: 'test-vitamin', name: 'Test Multivitamin', pack: 'Bottle of 30 tablets', mrp: 320, price: 272, rx: false, category: 'Vitamins'),
];

const awaitingNurseBooking = Booking(
  id: 'ALC-NUR-10001',
  type: BookingType.nurse,
  title: 'Wound Dressing',
  when: 'Today · Afternoon',
  status: 'Confirmed',
  amount: 749,
  otp: '1234',
  patientName: 'Test Patient',
  patientAge: 70,
  patientGender: 'Female',
  address: '1 Test Street, Test City',
  providerName: kAssignedNurseLabel,
);

const completedNurseBooking = Booking(
  id: 'ALC-NUR-10002',
  type: BookingType.nurse,
  title: 'Injection visit',
  when: 'Completed',
  status: 'Completed',
  amount: 499,
  otp: '5678',
  liveStatus: BookingLiveStatus.completed,
  patientName: 'Test Patient',
  address: '1 Test Street, Test City',
  providerName: 'Test Nurse',
  providerPhone: '+91 00000 00000',
  providerRating: 4.5,
  providerQualifications: 'GNM',
);

const centreBooking = Booking(
  id: 'ALC-CTR-10003',
  type: BookingType.careCentre,
  title: 'Test Care Centre · Private room',
  when: 'Check-in date confirmed by the centre · 30 Days',
  status: 'Requested',
  amount: 45000,
  otp: '9012',
  patientName: 'Test Patient',
  address: 'Test Locality, Test City',
  providerName: 'Test Care Centre',
  roomType: 'Private room',
);

class FixturePartnersSource extends PartnersSource {
  const FixturePartnersSource();

  @override
  Future<PartnerRows> fetch() async => PartnerRows(
        partners: const [testNurseRow, testCaregiverRow, testCentreRow],
        offeringsByPartner: {testNurseRow['id'] as String: testOfferingRows},
      );
}

class FixtureEquipmentService extends EquipmentService {
  const FixtureEquipmentService();

  @override
  Future<List<Equipment>> fetchAll() async => [equipmentFromRow(testEquipmentRow)];
}

/// Overrides that make every data source return the fixtures above.
List<Override> seededOverrides() => [
      partnersSourceProvider.overrideWithValue(const FixturePartnersSource()),
      equipmentServiceProvider.overrideWithValue(const FixtureEquipmentService()),
      bookingsServiceProvider.overrideWithValue(
        BookingsService([awaitingNurseBooking, completedNurseBooking, centreBooking]),
      ),
      medicineCatalogProvider.overrideWith((ref) async {
        MedicineCatalog.replaceAll(testMedicines);
        return MedicineCatalog.all;
      }),
    ];

import 'package:flutter_test/flutter_test.dart';
import 'package:allcuro/features/services/data/services_catalog.dart';
import 'package:allcuro/features/services/data/models/service_category.dart';
import 'package:allcuro/features/centres/data/centres_service.dart';
import 'package:allcuro/features/equipment/data/equipment_service.dart';
import 'package:allcuro/features/nurses/data/models/nurse.dart';
import 'package:allcuro/features/nurses/data/nurses_service.dart';
import 'package:allcuro/features/partners/data/partners_source.dart';

import 'fixtures.dart';

void main() {
  group('ServicesCatalog & Nursing Degree Matching Tests', () {
    test('contains all essential home care categories from docx catalog', () {
      final services = ServicesCatalog.allServices;
      expect(services.length, greaterThanOrEqualTo(12));

      final quickCare = ServicesCatalog.getById('quick-care');
      expect(quickCare, isNotNull);
      expect(quickCare!.group, ServiceGroup.instant);

      final woundCare = ServicesCatalog.getById('wound-care');
      expect(woundCare, isNotNull);
      expect(woundCare!.requiredDegree, contains('GNM'));
      expect(woundCare.nurseDegreeFilters, contains('GNM'));
      expect(woundCare.procedures.length, greaterThanOrEqualTo(4));

      final icuCare = ServicesCatalog.getById('icu-critical-care');
      expect(icuCare, isNotNull);
      expect(icuCare!.requiredDegree, contains('Critical Care'));
      expect(icuCare.nurseDegreeFilters, contains('Critical Care Certified'));

      final physio = ServicesCatalog.getById('physiotherapy');
      expect(physio, isNotNull);
      expect(physio!.requiredDegree, contains('BPT'));

      final attendant = ServicesCatalog.getById('elderly-attendant');
      expect(attendant, isNotNull);
      expect(attendant!.requiredDegree, contains('GDA'));
    });

    test('NursesService returns no nurses without approved partners (no demo data)', () async {
      final nurses = await NursesService(() async => PartnerRows.empty).fetchAll();
      expect(nurses, isEmpty);
    });

    test('PartnersSource is empty when Supabase is not configured', () async {
      expect((await const PartnersSource().fetch()).partners, isEmpty);
    });

    test('NursesService maps approved individual partners and their admin rates', () async {
      final nurses = await NursesService(() => const FixturePartnersSource().fetch()).fetchAll();
      expect(nurses.map((n) => n.id), ['test-nurse', 'test-caregiver'], reason: 'centres are excluded');

      final n = nurses.first;
      expect(n.name, 'Test Nurse');
      expect(n.photo, isEmpty, reason: 'no photo_url → initials avatar, never a stock photo');
      expect(n.level, 'GNM Diploma');
      expect(n.city, 'Test Locality, Test City');
      expect(n.tags, ['Wound Dressing', 'Injections & IV', 'Elderly Care']);
      expect(n.employment, Employment.partTime);
      expect(n.reviews, 0);
      expect(n.shifts.single.price, 630, reason: 'final_price from partner_offerings_public');
      expect(n.shifts.single.mrp, 700);
      expect(n.shifts.single.serviceId, 'wound-dressing');

      final c = nurses.last;
      expect(c.kind, 'caregiver');
      expect(c.level, 'GDA', reason: 'falls back to qualification when headline is empty');
      expect(c.available, isFalse);
      expect(c.rating, 4.5);
      expect(c.shifts, isEmpty);
    });

    test('CentresService maps centre partners with the admin discount applied', () async {
      final centres = await CentresService(() => const FixturePartnersSource().fetch()).fetchAll();
      final c = centres.single;
      expect(c.id, 'test-centre');
      expect(c.type, 'Rehab & recovery');
      expect(c.pricePerDay, 1800);
      expect(c.pricePerMonth, 45000);
      expect(c.roomTypes, ['Shared room', 'Private room']);
      expect(c.scores, isEmpty, reason: 'no invented quality scores');
      expect(await CentresService(() async => PartnerRows.empty).fetchAll(), isEmpty);
    });

    test('equipment rows map to discounted rates; no Supabase → empty', () async {
      final e = equipmentFromRow(testEquipmentRow);
      expect(e.id, 'test-wheelchair');
      expect(e.perDay, 90);
      expect(e.perMonth, 1800);
      expect(e.inStock, isTrue);
      expect(EquipmentService.categoriesOf([e]), ['Mobility']);
      expect(await const EquipmentService().fetchAll(), isEmpty);
    });
  });
}

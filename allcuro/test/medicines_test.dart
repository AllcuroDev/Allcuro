import 'package:allcuro/core/theme/app_theme.dart';
import 'package:allcuro/features/bookings/data/models/booking.dart';
import 'package:allcuro/features/bookings/presentation/bookings_view_model.dart';
import 'package:allcuro/features/medicines/data/medicine.dart';
import 'package:allcuro/features/medicines/presentation/medicine_cart_screen.dart';
import 'package:allcuro/features/medicines/presentation/medicine_cart_view_model.dart';
import 'package:allcuro/features/medicines/presentation/medicine_order_screen.dart';
import 'package:allcuro/features/medicines/presentation/medicines_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

Medicine _m(String id) => MedicineCatalog.byId(id)!;

const _pdf = PrescriptionFile(name: 'rx.pdf', sizeBytes: 120000, isPdf: true);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('MedicineCartState pricing', () {
    test('adds a ₹39 delivery fee below ₹499 and none from ₹499', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(medicineCartProvider.notifier);

      cart.add(_m('paracetamol-650')); // ₹30
      var s = c.read(medicineCartProvider);
      expect(s.itemTotal, 30);
      expect(s.deliveryFee, 39);
      expect(s.total, 69);
      expect(s.toFreeDelivery, 469);

      cart.setQty(_m('multivitamin'), 2); // + ₹544
      s = c.read(medicineCartProvider);
      expect(s.itemTotal, 574);
      expect(s.deliveryFee, 0);
      expect(s.total, 574);
      expect(s.savings, (34 - 30) + (320 - 272) * 2);
    });

    test('quantity is clamped to 1–10 and 0 removes the line', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(medicineCartProvider.notifier);

      cart.setQty(_m('cetirizine-10'), 25);
      expect(c.read(medicineCartProvider).qtyOf('cetirizine-10'), MedicinePricing.maxQty);
      cart.setQty(_m('cetirizine-10'), 0);
      expect(c.read(medicineCartProvider).lines, isEmpty);
      expect(c.read(medicineCartProvider).deliveryFee, 0, reason: 'no fee on an empty cart');
    });

    test('Rx medicines block checkout until a prescription is attached', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(medicineCartProvider.notifier).add(_m('amoxicillin-500'));
      final s = c.read(medicineCartProvider);
      expect(s.needsPrescription, isTrue);
      expect(s.canCheckout, isFalse);
    });

    test('search matches name, category and pack within a category', () {
      expect(MedicineCatalog.search('paracet').map((m) => m.id), ['paracetamol-650']);
      expect(MedicineCatalog.search('', category: 'Vitamins'), hasLength(3));
      expect(MedicineCatalog.search('syrup', category: 'Vitamins'), isEmpty);
      expect(MedicineCatalog.search('sachets').single.id, 'ors-orange');
    });
  });

  group('prescription review', () {
    test('adds the prescribed medicines and unlocks checkout', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(medicineCartProvider.notifier);
      cart.setQty(_m('metformin-500'), 5);

      final review = cart.attachPrescription(_pdf);
      expect(c.read(medicineCartProvider).prescriptionStatus, PrescriptionStatus.reviewing);
      expect(c.read(medicineCartProvider).canCheckout, isFalse);
      await review;

      final s = c.read(medicineCartProvider);
      expect(s.prescriptionStatus, PrescriptionStatus.reviewed);
      expect(s.qtyOf('metformin-500'), 5, reason: 'keeps a larger quantity the user chose');
      expect(s.qtyOf('amlodipine-5'), 1);
      expect(s.qtyOf('pantoprazole-40'), 1);
      expect(s.lines.every((l) => l.fromPrescription), isTrue);
      expect(s.canCheckout, isTrue);
    });

    test('a prescription removed mid-review adds nothing', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(medicineCartProvider.notifier);
      final review = cart.attachPrescription(_pdf);
      cart.removePrescription();
      await review;
      expect(c.read(medicineCartProvider).lines, isEmpty);
      expect(c.read(medicineCartProvider).prescriptionStatus, PrescriptionStatus.none);
    });
  });

  group('screens', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      String location, {
      Size size = const Size(320, 640),
      double textScale = 1.3,
      void Function(ProviderContainer)? seed,
    }) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      seed?.call(container);

      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/bookings', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/medicines', builder: (_, s) => MedicinesScreen(openUpload: s.uri.queryParameters['upload'] == '1')),
          GoRoute(path: '/medicines/cart', builder: (_, _) => const MedicineCartScreen()),
          GoRoute(path: '/medicine-order/:id', builder: (_, s) => MedicineOrderScreen(orderId: s.pathParameters['id']!)),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      return container;
    }

    for (final size in const [Size(320, 640), Size(412, 915)]) {
      testWidgets('medicine list lays out without overflow at ${size.width.toInt()}dp, 1.3× text', (tester) async {
        await pump(tester, '/medicines', size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('Medicines'), findsOneWidget);

        final vertical = find.byType(Scrollable).first;
        await tester.drag(vertical, const Offset(0, -400));
        await tester.pump();
        await tester.tap(find.text('ADD').hitTestable().first);
        await tester.pump();
        expect(find.textContaining('1 item · '), findsOneWidget, reason: 'cart bar appears');

        await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('cart with Rx items lays out and gates checkout at ${size.width.toInt()}dp', (tester) async {
        await pump(tester, '/medicines/cart', size: size, seed: (c) {
          final cart = c.read(medicineCartProvider.notifier);
          cart.setQty(_m('azithromycin-500'), 1);
          cart.setQty(_m('ors-orange'), 2);
        });
        expect(tester.takeException(), isNull);
        expect(find.text('Upload a prescription to order Rx medicines'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Prescription needed'), 200, scrollable: find.byType(Scrollable).first);
        expect(find.text('Prescription needed'), findsOneWidget);
        final placeOrder = tester.widget<ElevatedButton>(
          find.ancestor(of: find.text('Place order'), matching: find.byType(ElevatedButton)),
        );
        expect(placeOrder.onPressed, isNull);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('BILL SUMMARY'), findsOneWidget);
      });
    }

    testWidgets('a paid order shows its OTP and items', (tester) async {
      final c = await pump(tester, '/medicines');
      // Create an order the way the cart does, then open its page.
      final cart = c.read(medicineCartProvider.notifier);
      cart.setQty(_m('vitamin-d3'), 2);
      final bookings = c.read(bookingsViewModelProvider.notifier);
      await tester.runAsync(() => c.read(bookingsViewModelProvider.future));
      await tester.runAsync(() => bookings.createBooking(
            const Booking(
              id: 'ALC-MED-12345',
              type: BookingType.medicine,
              title: 'Medicine order · 2 items',
              when: 'Delivery today, within 3 hrs',
              status: 'Confirmed',
              amount: 269,
              otp: '5521',
              providerQualifications: 'Licensed pharmacy · UPI',
              items: ['Vitamin D3 60,000 IU Capsule × 2 · ₹230'],
            ),
          ));
      GoRouter.of(tester.element(find.byType(MedicinesScreen))).go('/medicine-order/ALC-MED-12345');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('5521'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Vitamin D3 60,000 IU Capsule × 2 · ₹230'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Vitamin D3 60,000 IU Capsule × 2 · ₹230'), findsOneWidget);
    });
  });
}

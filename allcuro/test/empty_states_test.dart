// With no approved partners (and no Supabase keys in tests) every list must
// show a friendly empty state — never demo people, centres or bookings.

import 'package:allcuro/app/router.dart';
import 'package:allcuro/core/content/site_contact.dart';
import 'package:allcuro/core/theme/app_theme.dart';
import 'package:allcuro/features/medicines/data/medicine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

Future<void> _pump(WidgetTester tester, String route, {List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(412, 915) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: GoRouter(initialLocation: route, routes: appRouter.configuration.routes),
    ),
  ));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => MedicineCatalog.replaceAll(const []));

  const demoNames = ['Priya', 'Rahul', 'Ramesh', 'Sharma', 'Menon', 'Serene Gardens', 'Sanjeevani'];
  void expectNoDemoNames() {
    for (final name in demoNames) {
      expect(find.textContaining(name), findsNothing, reason: 'demo name "$name" must not appear');
    }
  }

  final cases = {
    '/nurses': 'No nurses available yet',
    '/centres': 'No care centres listed yet',
    '/equipment': 'No equipment listed yet',
    '/medicines': 'No medicines listed yet',
    '/bookings': 'No bookings yet',
    '/services/wound-dressing': 'No nurses available yet',
  };
  cases.forEach((route, message) {
    testWidgets('$route shows "$message" with zero partners', (tester) async {
      await _pump(tester, route);
      await tester.scrollUntilVisible(find.text(message), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(message), findsOneWidget);
      expectNoDemoNames();
    });
  });

  testWidgets('empty state offers the care-desk number from site settings', (tester) async {
    await _pump(tester, '/nurses', overrides: [
      siteContactProvider.overrideWith((ref) async => const SiteContact(phoneDisplay: '+91 11111 22222')),
    ]);
    expect(find.text('Call care desk · +91 11111 22222'), findsOneWidget);
  });

  testWidgets('without a care-desk number no placeholder number is shown', (tester) async {
    await _pump(tester, '/nurses');
    expect(find.textContaining('Call care desk'), findsNothing);
  });

  testWidgets('quick booking starts with empty patient fields', (tester) async {
    await _pump(tester, '/nurse-quick-booking');
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.controller?.text ?? '', isEmpty);
    }
    expectNoDemoNames();
  });

  testWidgets('a booking awaiting assignment shows a generic care-desk nurse', (tester) async {
    await _pump(tester, '/nurse-tracker/${awaitingNurseBooking.id}', overrides: seededOverrides());
    expect(find.textContaining('assigned by our care desk'), findsWidgets);
    expect(find.text('Awaiting nurse'), findsOneWidget);
    expect(find.text('Rate Nurse'), findsNothing);
    expectNoDemoNames();
  });

  testWidgets('seeded partners render with initials instead of stock photos', (tester) async {
    await _pump(tester, '/nurses', overrides: seededOverrides());
    expect(find.text('Test Nurse'), findsOneWidget);
    expect(find.text('TN'), findsOneWidget);
    expect(find.text('New on ALLCURO'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

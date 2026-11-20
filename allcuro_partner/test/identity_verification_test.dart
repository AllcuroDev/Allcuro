import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allcuro_partner/features/identity/data/identity_service.dart';
import 'package:allcuro_partner/main.dart';

Finder _field(String key) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));

Future<void> _openIdentityStep(WidgetTester tester, String role) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'auth.logged_in': true, 'auth.role': role});
  await tester.pumpWidget(const ProviderScope(child: AllcuroPartnerApp()));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  // Tests run without Supabase keys, so the NRTS / NMC edge functions are
  // never called: these check the forms and that an unconnected build fails
  // clearly instead of inventing a verified person.

  testWidgets('nurse verifies with NUID only', (tester) async {
    await _openIdentityStep(tester, 'nurse');

    expect(find.text('Verify your NUID'), findsOneWidget);
    expect(_field('registered-name'), findsNothing); // NRTS returns the name
    final verify = find.widgetWithText(ElevatedButton, 'Verify NUID');
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNull);

    await tester.enterText(_field('registration-number'), 'abc123456');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNotNull);

    await tester.tap(verify);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Supabase keys missing'), findsOneWidget);
    expect(find.text('NUID verified with INC'), findsNothing);
  });

  testWidgets('doctor verifies name + registration number with NMC', (tester) async {
    await _openIdentityStep(tester, 'clinician');

    expect(find.text('Verify your NMC registration'), findsOneWidget);
    expect(find.text('State Medical Council (optional)'), findsOneWidget);
    expect(find.text('Year of registration (optional)'), findsOneWidget);

    final verify = find.widgetWithText(ElevatedButton, 'Verify with NMC');
    await tester.enterText(_field('registration-number'), '112345');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNull); // name still missing

    await tester.enterText(_field('registered-name'), 'Yukti Sharma');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNotNull);
  });

  test('Aadhaar numbers need 12 digits, a 2–9 lead and a valid Verhoeff check digit', () {
    expect(IdentityService.isValidAadhaar('234567890124'), isTrue);
    expect(IdentityService.isValidAadhaar('234567890123'), isFalse); // wrong check digit
    expect(IdentityService.isValidAadhaar('134567890124'), isFalse); // starts with 1
    expect(IdentityService.isValidAadhaar('23456789012'), isFalse); // 11 digits
  });

  test('register names are shown in natural order and case', () {
    expect(IdentityService.titleCaseName('SHARMA, YUKTI'), 'Yukti Sharma');
    expect(IdentityService.titleCaseName('PRIYA  K NAIR'), 'Priya K Nair');
  });
}

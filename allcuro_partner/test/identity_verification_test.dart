import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allcuro_partner/main.dart';

Finder _field(String key) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ElevatedButton, label));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new nurse verifies NUID and Aadhaar before the locked profile wizard', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'auth.logged_in': true, 'auth.role': 'nurse'});

    await tester.pumpWidget(const ProviderScope(child: AllcuroPartnerApp()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Step 1 — NUID. The registry mock echoes the name the nurse typed; it
    // never invents a person.
    expect(find.text('Verify your NUID'), findsOneWidget);
    await tester.enterText(_field('registered-name'), 'Anita Desai');
    await tester.enterText(_field('registration-number'), 'KA20170042');
    await tester.pump();
    await _tapButton(tester, 'Verify NUID');
    expect(find.text('NUID verified'), findsOneWidget);
    expect(find.text('Anita Desai'), findsWidgets); // typed field + verified card
    expect(find.text('Karnataka State Nursing Council'), findsOneWidget);
    await _tapButton(tester, 'Continue');

    // Step 2 — Aadhaar e-KYC.
    expect(find.text('Aadhaar verification'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '234567890123');
    await tester.pump();
    expect(find.text('2345 6789 0123'), findsOneWidget);
    await tester.tap(find.textContaining('I consent to ALLCURO using my Aadhaar'));
    await tester.pump();
    await _tapButton(tester, 'Send OTP');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await _tapButton(tester, 'Verify OTP');
    expect(find.text('Aadhaar verified'), findsOneWidget);
    expect(find.text('XXXX XXXX 0123'), findsOneWidget);
    await _tapButton(tester, 'Continue to profile');

    // Sign-up wizard: the verified name is locked; details e-KYC didn't
    // return (date of birth, gender, address) are left for the nurse to enter.
    expect(find.text('Verified from Aadhaar'), findsOneWidget);
    expect(find.text('Anita Desai'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsNothing);
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);

    // Skipping lands on the dashboard, where identity shows as already verified.
    await tester.tap(find.text('Skip for now'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Identity & Basic Profile'), findsOneWidget);
    expect(find.textContaining('NUID KA20170042 verified at sign-up'), findsOneWidget);
    expect(find.text('Anita Desai'), findsOneWidget);
  });

  testWidgets('wrong Aadhaar OTP is rejected', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'auth.logged_in': true, 'auth.role': 'clinician'});

    await tester.pumpWidget(const ProviderScope(child: AllcuroPartnerApp()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Verify your registration'), findsOneWidget);
    await tester.tap(find.text('Doctor'));
    await tester.pump();
    await tester.tap(find.text('Karnataka Medical Council'));
    await tester.pump();
    await tester.enterText(_field('registered-name'), 'Rahul Mehta');
    await tester.enterText(_field('registration-number'), 'KMC-123456');
    await tester.pump();
    await _tapButton(tester, 'Verify registration');
    expect(find.text('MBBS'), findsOneWidget);
    await _tapButton(tester, 'Continue');

    await tester.enterText(find.byType(TextField), '234567890123');
    await tester.tap(find.textContaining('I consent to ALLCURO using my Aadhaar'));
    await tester.pump();
    await _tapButton(tester, 'Send OTP');
    await tester.enterText(find.byType(TextField).last, '000000');
    await tester.pump();
    await _tapButton(tester, 'Verify OTP');
    expect(find.text('Incorrect OTP. Please try again.'), findsOneWidget);
    expect(find.text('Aadhaar verified'), findsNothing);
  });
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allcuro_partner/features/auth/presentation/onboarding_view_model.dart';
import 'package:allcuro_partner/features/centre/presentation/revenue/revenue_screen.dart';
import 'package:allcuro_partner/features/centre/presentation/reviews/reviews_screen.dart';
import 'package:allcuro_partner/features/nurse/data/nurse_service.dart';
import 'package:allcuro_partner/features/centre/data/centre_service.dart';
import 'package:allcuro_partner/features/nurse/presentation/earnings/earnings_screen.dart';
import 'package:allcuro_partner/features/nurse/presentation/ratings/performance_screen.dart';
import 'package:allcuro_partner/features/nurse/presentation/ratings/ratings_screen.dart';
import 'package:allcuro_partner/features/nurse/presentation/referral/referral_screen.dart';
import 'package:allcuro_partner/features/nurse/presentation/requests/nurse_visit_execution_screen.dart';
import 'package:allcuro_partner/main.dart';

const _fabricatedNames = ['Priya Sharma', 'Ramesh Iyer', 'Lakshmi Rao', 'Sanjeevani Elder Care Sanctuary'];

void _expectNoFabricatedNames() {
  for (final name in _fabricatedNames) {
    expect(find.textContaining(name), findsNothing, reason: '"$name" is demo data');
  }
}

Future<void> _pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(const ProviderScope(child: AllcuroPartnerApp()));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await tester.pumpAndSettle();
}

final _nurseIdentity = jsonEncode({
  'fullName': 'Anita Desai',
  'dob': null,
  'gender': null,
  'address': '',
  'aadhaarLast4': '0123',
  'registrationLabel': 'NUID',
  'registrationNumber': 'KA20170042',
  'council': 'Karnataka State Nursing Council',
  'qualification': 'GNM',
  'profession': null,
});

void main() {
  test('services return no seeded data', () async {
    final nurse = NurseService();
    expect(await nurse.fetchPendingRequests(), isEmpty);
    expect(await nurse.fetchShifts(), isEmpty);
    expect(await nurse.fetchActiveVisit(), isNull);
    final perf = await nurse.fetchPerformance();
    expect(perf.hasActivity, isFalse);
    expect(perf.feedbacks, isEmpty);

    final centre = CentreService();
    expect(await centre.fetchPendingRequests(), isEmpty);
    expect(await centre.fetchRooms(), isEmpty);
    expect(await centre.fetchAdmittedThisMonth(), 0);
  });

  test('partner-entered inventory starts empty and not uploaded', () {
    const s = PartnerOnboardingState.initial;
    expect(s.rooms, isEmpty);
    expect(s.staffMembers, isEmpty);
    expect(s.equipmentList, isEmpty);
    expect(s.nurseSkills, isEmpty);
    expect(s.bankAccount.isConfigured, isFalse);
    expect(s.centreComplianceDocs, isNotEmpty);
    expect(s.centreComplianceDocs.any((d) => d.isUploaded || d.isVerified), isFalse);
    expect(s.nurseDocs.any((d) => d.isUploaded || d.isVerified), isFalse);
    expect(s.canSubmitNurseForReview, isFalse);
    expect(s.canSubmitCentreForReview, isFalse);
  });

  testWidgets('verified nurse home shows her own name and empty requests', (tester) async {
    await _pumpApp(tester, {
      'auth.logged_in': true,
      'auth.role': 'nurse',
      'auth.nurse_verification_status': 'verified',
      'auth.nurse_identity': _nurseIdentity,
    });

    expect(find.text('Anita Desai'), findsOneWidget);
    expect(find.textContaining('No visit requests yet'), findsOneWidget);
    expect(find.textContaining('No upcoming shifts yet'), findsOneWidget);
    _expectNoFabricatedNames();
  });

  testWidgets('nurse under review sees honest pending steps', (tester) async {
    await _pumpApp(tester, {
      'auth.logged_in': true,
      'auth.role': 'nurse',
      'auth.nurse_verification_status': 'underReview',
      'auth.nurse_identity': _nurseIdentity,
    });

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Passed'), findsNothing);
    expect(find.text('Clean Record'), findsNothing);
    expect(find.text('Awaiting ALLCURO review'), findsWidgets);
  });

  testWidgets('centre home falls back to a neutral name and shows no fake officer', (tester) async {
    await _pumpApp(tester, {
      'auth.logged_in': true,
      'auth.role': 'centre',
      'auth.centre_verification_status': 'pendingReview',
    });

    expect(find.text('Your centre'), findsOneWidget);
    expect(find.text('Site visit: not scheduled yet'), findsOneWidget);
    expect(find.textContaining('Kiran Rao'), findsNothing);
    _expectNoFabricatedNames();
  });

  testWidgets('centre home shows the name entered at sign-up', (tester) async {
    await _pumpApp(tester, {
      'auth.logged_in': true,
      'auth.role': 'centre',
      'auth.centre_verification_status': 'onboarding',
      'auth.centre_display_name': 'Green Valley Care Home',
    });

    expect(find.text('Green Valley Care Home'), findsOneWidget);
    expect(find.text('Add Rooms'), findsOneWidget);
    _expectNoFabricatedNames();
  });

  testWidgets('no-backend screens show empty states', (tester) async {
    void back() {}
    final cases = <Widget, String>{
      EarningsScreen(onBack: back): 'No earnings yet',
      RatingsScreen(onBack: back): 'No reviews yet',
      PerformanceScreen(onBack: back): 'No performance data yet',
      ReferralScreen(onBack: back): 'No referrals yet',
      NurseVisitExecutionScreen(onBack: back): 'No active visit',
      RevenueScreen(onBack: back): 'No revenue yet',
      ReviewsScreen(onBack: back): 'No reviews yet',
    };
    for (final entry in cases.entries) {
      await _pumpScreen(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key.runtimeType.toString());
      expect(find.textContaining('₹'), findsNothing, reason: entry.key.runtimeType.toString());
      _expectNoFabricatedNames();
    }
  });
}

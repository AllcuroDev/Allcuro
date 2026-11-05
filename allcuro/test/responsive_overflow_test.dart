// Responsive layout regression test.
//
// Pumps every customer-facing screen (and the bottom sheets) at real-phone
// sizes and system font scales, scrolls through every scrollable, and fails on
// any RenderFlex / layout overflow.
//
// The real Plus Jakarta Sans files (test/fonts, the exact files google_fonts
// downloads at runtime) are loaded under google_fonts' family names so text
// metrics match the device instead of the square "FlutterTest" glyphs.

import 'dart:io';

import 'package:allcuro/app/router.dart';
import 'package:allcuro/core/theme/app_theme.dart';
import 'package:allcuro/features/auth/presentation/quick_login_sheet.dart';
import 'package:allcuro/features/location/presentation/location_sheet.dart';
import 'package:allcuro/features/services/presentation/all_nurse_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sizes = <Size>[Size(320, 640), Size(360, 740), Size(412, 915)];
const _textScales = <double>[1.0, 1.3];

typedef _Step = Future<void> Function(WidgetTester tester);

class _Case {
  final String name;
  final String route;
  final List<_Step> steps;

  /// Also lay the screen out with a 300dp software keyboard up.
  final bool keyboard;

  const _Case(this.route, {String? name, this.steps = const [], this.keyboard = false})
      : name = name ?? route;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets, reason: 'flow step target missing: $finder');
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first, warnIfMissed: false);
  await _settle(tester);
}

Future<void> _enter(WidgetTester tester, String text) async {
  final field = find.byType(TextField, skipOffstage: false);
  expect(field, findsWidgets);
  await tester.enterText(field.first, text);
  await tester.pump();
}

/// Screens to audit. Paths match lib/app/router.dart.
final _cases = <_Case>[
  const _Case('/splash'),
  const _Case('/welcome'),
  const _Case('/auth/phone', keyboard: true),
  _Case('/auth/phone', name: '/auth/phone (OTP step)', keyboard: true, steps: [
    (t) => _enter(t, '9876543210'),
    (t) => _tap(t, find.text('Continue')),
  ]),
  const _Case('/onboarding', keyboard: true),
  const _Case('/'),
  const _Case('/category-services/all'),
  const _Case('/category-services/nursing'),
  const _Case('/category-services/mother-baby'),
  const _Case('/category-services/elder-care'),
  const _Case('/category-services/physiotherapy'),
  const _Case('/category-services/doctor-care'),
  const _Case('/category-services/hospital-companion'),
  const _Case('/nurse-services'),
  const _Case('/__all-nurse-services'),
  const _Case('/services/wound-dressing'),
  _Case('/services/wound-dressing', name: '/services/wound-dressing (slot sheet)', steps: [
    (t) => _tap(t, find.byWidgetPredicate((w) => w.runtimeType.toString() == '_NurseCard')),
  ]),
  const _Case('/services/mother-baby-2-hour-support'),
  const _Case('/services/quick-care'),
  const _Case('/nurses'),
  const _Case('/nurses/priya-sharma'),
  const _Case('/nurse-quick-booking'),
  const _Case('/nurse-tracker/ALC-NUR-8921'),
  _Case('/nurse-tracker/ALC-NUR-8921', name: '/nurse-tracker (SOS dialog)', steps: [
    (t) => _tap(t, find.text('SOS')),
  ]),
  const _Case('/nurse-tracker/ALC-NUR-82554'),
  _Case('/nurse-tracker/ALC-NUR-82554', name: '/nurse-tracker (rating sheet)', keyboard: true, steps: [
    (t) => _tap(t, find.text('Rate Nurse')),
  ]),
  const _Case('/centres'),
  const _Case('/centres/serene-gardens'),
  const _Case('/centre-booking/serene-gardens'),
  const _Case('/centre-pass/ALC-CTR-4920'),
  const _Case('/equipment'),
  const _Case('/medicines'),
  const _Case('/medicines/cart'),
  const _Case('/bookings'),
  const _Case('/checkout'),
  const _Case('/profile'),
  const _Case('/faq'),
  const _Case('/__sheet/quick-login', keyboard: true),
  _Case('/__sheet/quick-login', name: '/__sheet/quick-login (OTP step)', keyboard: true, steps: [
    (t) => _enter(t, '9876543210'),
    (t) => _tap(t, find.text('Send OTP Verification')),
  ]),
  const _Case('/__sheet/location', keyboard: true),
  _Case('/__sheet/location', name: '/__sheet/location (add address)', keyboard: true, steps: [
    (t) => _tap(t, find.text('Add New Address')),
  ]),
];

Future<void> _loadFonts() async {
  const weights = {
    'regular': 'PlusJakartaSans_regular',
    '500': 'PlusJakartaSans_500',
    '600': 'PlusJakartaSans_600',
    '700': 'PlusJakartaSans_700',
    '800': 'PlusJakartaSans_800',
  };
  for (final entry in weights.entries) {
    final file = File('test/fonts/PlusJakartaSans-${entry.key}.ttf');
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    final loader = FontLoader(entry.value)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

class _SheetLauncher extends StatefulWidget {
  final Future<void> Function(BuildContext context) open;
  const _SheetLauncher(this.open);

  @override
  State<_SheetLauncher> createState() => _SheetLauncherState();
}

class _SheetLauncherState extends State<_SheetLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.open(context);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}

GoRouter _buildRouter(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        ...appRouter.configuration.routes,
        GoRoute(
          path: '/__all-nurse-services',
          builder: (context, state) => const AllNurseServicesScreen(),
        ),
        GoRoute(
          path: '/__sheet/quick-login',
          builder: (context, state) => _SheetLauncher((c) => QuickLoginSheet.show(c)),
        ),
        GoRoute(
          path: '/__sheet/location',
          builder: (context, state) => _SheetLauncher(LocationSheet.show),
        ),
      ],
    );

String _describe(FlutterErrorDetails d) {
  final exception = d.exceptionAsString().replaceAll('\n', ' ').trim();
  final text = d.toString();
  final match = RegExp(r'(?:allcuro/lib/|package:allcuro/)[^\s:]+\.dart:\d+(?::\d+)?').firstMatch(text);
  final creator = match?.group(0)?.replaceFirst(RegExp(r'^.*?(lib/|package:allcuro/)'), 'lib/') ?? '';
  if (creator.isEmpty) {
    // Overflow inside a package widget: report the package source location.
    final pkg = RegExp(r'error-causing widget was:\s*\n\s*\S+\s*\n\s*\S+?:(\S+\.dart:\d+)').firstMatch(text)?.group(1);
    return '$exception @ ${pkg?.replaceFirst(RegExp(r'^.*/pub\.dev/'), '') ?? '?'}';
  }
  return '$exception @ $creator';
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Scrolls every scrollable on screen from start to end (vertical and
/// horizontal) so lazily-built children get laid out too.
Future<void> _scrollEverything(WidgetTester tester) async {
  final count = find.byType(Scrollable, skipOffstage: false).evaluate().length;
  for (var i = 0; i < count && i < 30; i++) {
    final all = find.byType(Scrollable, skipOffstage: false).evaluate().toList();
    if (i >= all.length) break;
    final state = (all[i] as StatefulElement).state as ScrollableState;
    final position = state.position;
    if (!position.hasContentDimensions || !position.hasViewportDimension) continue;
    var steps = 0;
    while (position.pixels < position.maxScrollExtent && steps < 40) {
      final target = (position.pixels + position.viewportDimension * 0.8)
          .clamp(0.0, position.maxScrollExtent);
      position.jumpTo(target);
      await tester.pump(const Duration(milliseconds: 50));
      if (!state.mounted) break;
      steps++;
    }
    if (state.mounted) {
      position.jumpTo(0);
      await tester.pump();
    }
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  for (final c in _cases) {
    final route = c.route;
    for (final size in _sizes) {
      for (final scale in _textScales) {
        testWidgets(
          'no overflow: ${c.name} @ ${size.width.toInt()}x${size.height.toInt()} x$scale',
          (tester) async {
            SharedPreferences.setMockInitialValues({});
            const dpr = 3.0;
            tester.view.devicePixelRatio = dpr;
            tester.view.physicalSize = size * dpr;
            tester.view.padding = const FakeViewPadding(top: 32 * dpr, bottom: 24 * dpr);
            tester.view.viewPadding = const FakeViewPadding(top: 32 * dpr, bottom: 24 * dpr);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearAllTestValues);

            final errors = <String>[];
            final previous = FlutterError.onError;
            FlutterError.onError = (details) {
              final msg = details.exceptionAsString();
              // google_fonts complains (asynchronously) that it cannot fetch
              // fonts; we've preloaded them ourselves.
              if (msg.contains('google_fonts') || msg.contains('allowRuntimeFetching')) {
                return;
              }
              errors.add(_describe(details));
            };

            try {
              await tester.pumpWidget(ProviderScope(
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: buildAppTheme(),
                  routerConfig: _buildRouter(route),
                ),
              ));
              await _settle(tester);
              for (final step in c.steps) {
                await step(tester);
              }
              await _scrollEverything(tester);
              await _settle(tester);

              // Re-run forms / sheets with the keyboard up.
              if (c.keyboard) {
                tester.view.viewInsets = FakeViewPadding(bottom: 300 * dpr);
                await _settle(tester);
                await _scrollEverything(tester);
                tester.view.resetViewInsets();
                await tester.pump();
              }

              // Let splash/redirect timers fire, then tear the tree down.
              await tester.pump(const Duration(seconds: 4));
              await _settle(tester);
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump(const Duration(seconds: 2));
            } finally {
              FlutterError.onError = previous;
            }

            // Drain anything the binding captured itself.
            Object? pending = tester.takeException();
            while (pending != null) {
              if (!pending.toString().contains('google_fonts') &&
                  !pending.toString().contains('allowRuntimeFetching')) {
                errors.add(pending.toString().split('\n').first);
              }
              pending = tester.takeException();
            }

            final layoutErrors = errors.toSet().toList();
            expect(layoutErrors, isEmpty,
                reason: 'Layout errors on ${c.name} at ${size.width}x${size.height} '
                    'scale $scale:\n${layoutErrors.join('\n')}');
          },
        );
      }
    }
  }
}

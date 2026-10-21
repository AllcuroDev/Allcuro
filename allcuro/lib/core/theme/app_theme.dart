import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens ported 1:1 from `src/styles.css` (oklch → sRGB) so the
/// Flutter app matches the ALLCURO web theme exactly: a warm off-white base,
/// forest-green brand colour used for both primary and accent roles, and a
/// soft-mint tint for verified/availability signals and icon tiles.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF1A1814);
  static const card = Color(0xFFFFFFFF);

  /// Brand colour — header/gradient, icons, links, selected states.
  static const primary = Color(0xFF26593B);
  static const primaryForeground = Color(0xFFF9FDFA);
  static const primarySoft = Color(0xFFDDF4E4);
  static const primaryDeep = Color(0xFF0C341E);

  static const secondary = Color(0xFFF0F5F1);
  static const secondaryForeground = Color(0xFF263129);
  static const muted = Color(0xFFF0F5F1);
  static const mutedForeground = Color(0xFF646B66);

  static const accent = Color(0xFF3A8357);
  static const accentForeground = Color(0xFFF9FDFA);
  static const accentSoft = Color(0xFFDDF4E4);

  /// Verified badges, availability/vacancy signals.
  static const success = Color(0xFF419363);
  static const successSoft = Color(0xFFDDF4E4);

  /// Secondary brand accent — Vibrant Amber/Tangerine (#ED6C00).
  /// High-energy, warm clinical accent for urgent services (45-min nurse),
  /// express delivery badges, live active tracking states, and emergency chips.
  static const secondaryAccent = Color(0xFFED6C00);
  static const secondaryAccentSoft = Color(0xFFFFF3E6);
  static const secondaryAccentBorder = Color(0xFFFFD8B3);

  /// Muted amber — used sparingly: pending KYC, expiring documents.
  static const warning = Color(0xFFED6C00);
  static const warningSoft = Color(0xFFFFF3E6);

  static const destructive = Color(0xFFDA2B29);
  static const destructiveForeground = Color(0xFFFFFFFF);

  static const border = Color(0xFFE3E7E4);
  static const input = Color(0xFFE3E7E4);
  static const ring = Color(0xFF26593B);
  static const ink = Color(0xFF111512);

  /// `--gradient-primary` — used behind the app header (AppShell) and
  /// the pre-auth screens. Horizontal gradient from dark green (left) to light green (right).
  static const gradientPrimary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF143621), Color(0xFF26593B), Color(0xFF43845B)],
    stops: [0.0, 0.5, 1.0],
  );
}

/// Corner-radius scale — mirrors the `--radius-*` scale (base `--radius`:
/// 1rem == 16px).
class AppRadius {
  AppRadius._();

  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 28.0;
  static const xxxxl = 32.0;
  static const pill = 999.0;
}

/// Plus Jakarta Sans with heavy-weight bias for titles and headers.
TextStyle appHeadingStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final jakarta = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.card,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: AppColors.destructive,
      onError: AppColors.destructiveForeground,
      onSurface: AppColors.foreground,
    ),
    textTheme: jakarta.apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    ),
    dividerColor: AppColors.border,
  );
}

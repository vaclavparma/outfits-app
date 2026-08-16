import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted from the Šatník mockup (Satnik.dc.html).
class AppColors {
  AppColors._();

  static const background = Color(0xFFFAFAFA);
  static const cardFill = Color(0xFFF3F3F2);
  static const cardBorder = Color(0xFFE6E5E3);
  static const dashedBorder = Color(0xFFDEDCD8);
  static const ink = Color(0xFF141414);
  static const inkSoft = Color(0xFF2B2A28);
  static const label = Color(0xFF3D3B39);
  static const muted = Color(0xFF8A8784);
  static const mutedSoft = Color(0xFFB5B2AD);
  static const mutedTag = Color(0xFFA5A29D);
  static const mutedLabel = Color(0xFFADABA7);
  static const hairline = Color(0xFFEEECEA);
  static const rowBorder = Color(0xFFECEAE7);
  static const chipBorderIdle = Color(0xFFE6E5E3);
  static const chipTextIdle = Color(0xFF5C5955);

  /// oklch(0.55 0.09 25) converted to sRGB — the warm clay accent used for
  /// primary actions and links throughout the mockup.
  static const accent = Color(0xFFA0585B);
  static const accentDark = Color(0xFF8A4B4E);
}

class AppText {
  AppText._();

  static TextStyle sans({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.inkSoft,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.libreFranklin(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono({
    double size = 9,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.mutedTag,
    double? height,
    double letterSpacing = 0.4,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.libreFranklin().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.background,
    ),
    splashFactory: NoSplash.splashFactory,
  );
}

import 'package:flutter/material.dart';

/// One full set of the app's colors — see [AppColors].
class AppPalette {
  final Color background;
  final Color surface;
  final Color cardFill;
  final Color cardBorder;
  final Color dashedBorder;
  final Color ink;
  final Color inkSoft;
  final Color label;
  final Color muted;
  final Color mutedSoft;
  final Color mutedTag;
  final Color mutedLabel;
  final Color hairline;
  final Color rowBorder;
  final Color chipBorderIdle;
  final Color chipTextIdle;
  final Color removeButtonBorder;
  final Color emptyStateBorder;
  final Color accent;
  final Color accentDark;
  final Color danger;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.cardFill,
    required this.cardBorder,
    required this.dashedBorder,
    required this.ink,
    required this.inkSoft,
    required this.label,
    required this.muted,
    required this.mutedSoft,
    required this.mutedTag,
    required this.mutedLabel,
    required this.hairline,
    required this.rowBorder,
    required this.chipBorderIdle,
    required this.chipTextIdle,
    required this.removeButtonBorder,
    required this.emptyStateBorder,
    required this.accent,
    required this.accentDark,
    required this.danger,
  });

  /// Design tokens lifted from the Šatník mockup (Satnik.dc.html).
  static const light = AppPalette(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    cardFill: Color(0xFFF3F3F2),
    cardBorder: Color(0xFFE6E5E3),
    dashedBorder: Color(0xFFDEDCD8),
    ink: Color(0xFF141414),
    inkSoft: Color(0xFF2B2A28),
    label: Color(0xFF3D3B39),
    muted: Color(0xFF8A8784),
    mutedSoft: Color(0xFFB5B2AD),
    mutedTag: Color(0xFFA5A29D),
    mutedLabel: Color(0xFFADABA7),
    hairline: Color(0xFFEEECEA),
    rowBorder: Color(0xFFECEAE7),
    chipBorderIdle: Color(0xFFE6E5E3),
    chipTextIdle: Color(0xFF5C5955),
    removeButtonBorder: Color(0xFFEAE9E7),
    emptyStateBorder: Color(0xFFE2E0DC),
    accent: Color(0xFF006D77),
    accentDark: Color(0xFF004852),
    danger: Color(0xFFD64541),
  );

  /// The same warm greys, inverted: near-black surfaces with light ink. The
  /// accent is a touch lighter so it still reads on dark, while white text
  /// on it keeps enough contrast (~4.8:1).
  static const dark = AppPalette(
    background: Color(0xFF141413),
    surface: Color(0xFF1E1D1B),
    cardFill: Color(0xFF262523),
    cardBorder: Color(0xFF34322F),
    dashedBorder: Color(0xFF3D3B37),
    ink: Color(0xFFEDEBE8),
    inkSoft: Color(0xFFD9D6D2),
    label: Color(0xFFC9C6C1),
    muted: Color(0xFF9C9893),
    mutedSoft: Color(0xFF75716C),
    mutedTag: Color(0xFF85817C),
    mutedLabel: Color(0xFF7A7773),
    hairline: Color(0xFF2C2B28),
    rowBorder: Color(0xFF2F2D2A),
    chipBorderIdle: Color(0xFF3A3835),
    chipTextIdle: Color(0xFFB3AFAA),
    removeButtonBorder: Color(0xFF3A3835),
    emptyStateBorder: Color(0xFF3A3835),
    accent: Color(0xFF177E88),
    accentDark: Color(0xFF0E5C64),
    danger: Color(0xFFC9403C),
  );
}

/// The app's colors, for whichever of [AppPalette.light] / [AppPalette.dark]
/// is in effect. Plain getters rather than an InheritedWidget so the 170-odd
/// call sites can stay as they are; the app root swaps [current] and
/// rebuilds the whole tree when the brightness changes (see main.dart).
/// Photos keep a white surround either way — the product shots themselves
/// are on white.
class AppColors {
  AppColors._();

  static AppPalette current = AppPalette.light;

  static Color get background => current.background;

  /// Sheets, cards, dialogs, menus, chips — white in light mode.
  static Color get surface => current.surface;
  static Color get cardFill => current.cardFill;
  static Color get cardBorder => current.cardBorder;
  static Color get dashedBorder => current.dashedBorder;
  static Color get ink => current.ink;
  static Color get inkSoft => current.inkSoft;
  static Color get label => current.label;
  static Color get muted => current.muted;
  static Color get mutedSoft => current.mutedSoft;
  static Color get mutedTag => current.mutedTag;
  static Color get mutedLabel => current.mutedLabel;
  static Color get hairline => current.hairline;
  static Color get rowBorder => current.rowBorder;
  static Color get chipBorderIdle => current.chipBorderIdle;
  static Color get chipTextIdle => current.chipTextIdle;
  static Color get removeButtonBorder => current.removeButtonBorder;
  static Color get emptyStateBorder => current.emptyStateBorder;

  /// Teal accent for primary actions and links.
  static Color get accent => current.accent;
  static Color get accentDark => current.accentDark;

  /// Red for destructive actions; white text on it.
  static Color get danger => current.danger;
}

class AppText {
  AppText._();

  static TextStyle sans({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Libre Franklin',
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.inkSoft,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono({
    double size = 9,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacing = 0.4,
  }) {
    return TextStyle(
      fontFamily: 'IBM Plex Mono',
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.mutedTag,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.background,
    fontFamily: 'Libre Franklin',
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
      primary: p.accent,
      surface: p.background,
    ),
    splashFactory: NoSplash.splashFactory,
  );
}

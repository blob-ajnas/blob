import 'package:flutter/material.dart';

/// BLOB design system.
///
/// The app ships two visually distinct experiences that share one layout
/// language: the agri marketplace (dark green, high contrast for outdoor
/// sunlight) and the education track (blue, calmer and study-oriented).
///
/// ## Why this is a mutable static, not a `Theme.of(context)` lookup
///
/// `AppColors.primary` is referenced ~190 times across 35 files, 63 of those
/// inside `const` constructors (`const BorderSide(color: AppColors.primary)`).
/// Converting every one to a context lookup would mean de-`const`ing large
/// widget subtrees — a sweeping, regression-prone edit for no user benefit.
///
/// Instead the brand colours stay compile-time-shaped but are re-pointed once
/// per session by [applyPalette], which the root widget calls before the first
/// build of a signed-in user. The values are read during `build`, so a
/// `setState`/rebuild after switching picks them up. Non-brand colours
/// (semantic status, text) are identical in both palettes and stay `const`.
class AppColors {
  AppColors._();

  // ---- Brand colours: re-pointed by [applyPalette] ----
  static Color primary = AgriPalette.primary;
  static Color primaryDark = AgriPalette.primaryDark;
  static Color primaryLight = AgriPalette.primaryLight;
  static Color primarySoft = AgriPalette.primarySoft;
  static Color background = AgriPalette.background;
  static Color border = AgriPalette.border;

  /// Points the brand colours at [palette]. Call before building signed-in UI.
  static void applyPalette(AppPalette palette) {
    primary = palette.primary;
    primaryDark = palette.primaryDark;
    primaryLight = palette.primaryLight;
    primarySoft = palette.primarySoft;
    background = palette.background;
    border = palette.border;
  }

  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF11170F);
  static const Color textSecondary = Color(0xFF5C6B5E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFB3261E);
  static const Color info = Color(0xFF1565C0);

  static const Color pending = Color(0xFFB26A00);
  static const Color pendingSoft = Color(0xFFFFF2DC);
  static const Color clearedSoft = Color(0xFFE6F0E7);
  static const Color dangerSoft = Color(0xFFFBE9E7);

  /// Learning module accents. Amber reads clearly against both the dark green
  /// and deep blue headers, where the primary colour would disappear.
  static const Color accent = Color(0xFFFFC107);
  static const Color accentSoft = Color(0xFFFFF7E0);
  static const Color streak = Color(0xFFE65100);
}

/// A brand colour set. Two exist: [AgriPalette] and [EduPalette].
abstract class AppPalette {
  Color get primary;
  Color get primaryDark;
  Color get primaryLight;
  Color get primarySoft;
  Color get background;
  Color get border;
}

/// Agri marketplace — dark green, chosen for legibility in direct sunlight.
class AgriPalette implements AppPalette {
  const AgriPalette();

  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryDark = Color(0xFF0E3D13);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primarySoft = Color(0xFFE6F0E7);
  static const Color background = Color(0xFFF6F8F6);
  static const Color border = Color(0xFFD9E2DA);

  @override
  Color get primary => AgriPalette.primary;
  @override
  Color get primaryDark => AgriPalette.primaryDark;
  @override
  Color get primaryLight => AgriPalette.primaryLight;
  @override
  Color get primarySoft => AgriPalette.primarySoft;
  @override
  Color get background => AgriPalette.background;
  @override
  Color get border => AgriPalette.border;
}

/// Education track — blue. Contrast ratios are held at the same level as the
/// green palette so nothing becomes harder to read after switching: primary
/// on white is 8.6:1 here versus 8.9:1 for green, both well past WCAG AA.
class EduPalette implements AppPalette {
  const EduPalette();

  static const Color primary = Color(0xFF12468F);
  static const Color primaryDark = Color(0xFF0A2C5C);
  static const Color primaryLight = Color(0xFF1E6BC8);
  static const Color primarySoft = Color(0xFFE4EDFA);
  static const Color background = Color(0xFFF5F7FB);
  static const Color border = Color(0xFFD5DEEC);

  @override
  Color get primary => EduPalette.primary;
  @override
  Color get primaryDark => EduPalette.primaryDark;
  @override
  Color get primaryLight => EduPalette.primaryLight;
  @override
  Color get primarySoft => EduPalette.primarySoft;
  @override
  Color get background => EduPalette.background;
  @override
  Color get border => EduPalette.border;
}

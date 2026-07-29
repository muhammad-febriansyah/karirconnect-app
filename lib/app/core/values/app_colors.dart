import 'package:flutter/material.dart';

/// Mirror of the web design tokens in
/// `/applications/laravel/karirconnect/resources/css/app.css`.
///
/// The web declares every token in OKLCH. The hex values here are what a
/// browser actually rasterises those OKLCH values to, so the two surfaces paint
/// the same colour. When a token changes in `app.css`, convert it rather than
/// eyeballing it — the inline hex comments in that file (e.g. `#1080e0` for
/// brand blue) are approximations and do not match what ships.
class AppColors {
  AppColors._();

  // ---- Brand -------------------------------------------------------------
  /// `--brand-blue` / `--primary` / `--ring`.
  static const Color primary = Color(0xFF008AEB);

  /// `--brand-cyan`.
  static const Color brandCyan = Color(0xFF2BCCEB);

  /// `--brand-navy` / `--secondary-foreground`. Headings use this, not black.
  static const Color brandNavy = Color(0xFF07005B);

  static const Color primaryForeground = Color(0xFFFCFCFC);

  // ---- Surfaces ----------------------------------------------------------
  /// `--background` / `--card` / `--popover`. The web page body is white;
  /// `muted` is what tints the alternating sections.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// `--muted`.
  static const Color muted = Color(0xFFF1F6FA);

  /// `--secondary`.
  static const Color secondary = Color(0xFFF0F6FC);

  /// `--accent` and `--accent-foreground`.
  static const Color accent = Color(0xFFE0F1FE);
  static const Color accentForeground = Color(0xFF0055B2);

  // ---- Text --------------------------------------------------------------
  /// `--foreground`.
  static const Color foreground = Color(0xFF071123);

  /// `--muted-foreground`.
  static const Color mutedForeground = Color(0xFF55647A);

  // ---- Elevation-free surfaces -------------------------------------------
  // Cards in this app are separated from the page by a *tonal step*, not by a
  // stroke or a shadow. That keeps the surface calm (no grid of outlined
  // boxes) and costs no raster layer. The three values below must stay
  // ordered light-to-dark or the separation collapses:
  //   background (#FFFFFF)  <  surfaceSoft  <  muted
  //
  /// Card fill. Anything that was a bordered white card becomes this.
  static const Color surfaceSoft = Color(0xFFF2F6FB);

  /// Fill for anything nested *inside* a `surfaceSoft` card — chips, logo
  /// tiles, avatars. White inverts cleanly against the tint with no stroke.
  static const Color surfaceInset = Color(0xFFFFFFFF);

  /// The warm accent, taken from the mid stop of [hotBadgeGradient] so it is a
  /// brand colour rather than a loose hex. Filter button + "Butuh Cepat".
  static const Color accentAmber = Color(0xFFFEA800);
  static const Color accentAmberSoft = Color(0xFFFFF2E0);
  static const Color accentAmberForeground = Color(0xFF9A5B00);

  /// Quick-menu tile tints, cycled in order. Four hues drawn from the brand
  /// family — blue, cyan, indigo, amber — so the grid reads as one set instead
  /// of a rainbow. Each `tileIcon` clears 4.5:1 on its paired `tileTint`.
  static const List<Color> tileTints = [
    Color(0xFFE3F0FE),
    Color(0xFFDDF3F9),
    Color(0xFFE7E9FA),
    Color(0xFFFFF1DE),
  ];
  static const List<Color> tileIcons = [
    Color(0xFF0A5FC4),
    Color(0xFF0A6E80),
    Color(0xFF3A40A6),
    Color(0xFF9A5B00),
  ];

  // ---- Lines and state ---------------------------------------------------
  /// `--border` / `--input`. Kept for the few places that still need a hairline
  /// (sheet grabbers, table rules); cards and inputs no longer use it.
  static const Color border = Color(0xFFE3E9EE);

  /// `--destructive`.
  static const Color destructive = Color(0xFFE7000B);

  /// Tonal fill for a destructive action, so it can drop its stroke without
  /// borrowing the blue `accent` (red on that only reaches 4.19:1).
  static const Color destructiveSoft = Color(0xFFFDECEC);
  static const Color destructiveForeground = Color(0xFFFAFAFA);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // ---- Charts ------------------------------------------------------------
  static const List<Color> chart = [
    Color(0xFF008AEB),
    Color(0xFF2BCCEB),
    Color(0xFF0850AB),
    Color(0xFF00B9C3),
    Color(0xFF1C69E3),
  ];

  // ---- Gradients ---------------------------------------------------------
  /// The landing hero: `bg-gradient-to-b from-[#1b5fd6] via-[#1550c4] to-[#103e9e]`.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B5FD6), Color(0xFF1550C4), Color(0xFF103E9E)],
  );

  /// The last stop of [heroGradient], so a block that continues below the
  /// header can butt against it seamlessly. Kept in sync by hand — a gradient's
  /// `colors.last` is not a compile-time constant.
  static const Color heroGradientEnd = Color(0xFF103E9E);

  /// The hero's primary button: `from-brand-blue to-[#1565E0]`.
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, Color(0xFF1565E0)],
  );

  /// The "Loker Butuh Cepat" badge: `from-orange-500 to-amber-500`.
  static const LinearGradient hotBadgeGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF6900), Color(0xFFFE9A00)],
  );

  // ---- Aliases kept for existing call sites ------------------------------
  static const Color textPrimary = foreground;
  static const Color textSecondary = mutedForeground;
  static const Color inactive = mutedForeground;
  static const Color error = destructive;
  static const Color primaryDark = brandNavy;
}

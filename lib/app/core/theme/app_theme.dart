import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../values/app_colors.dart';

/// Radii the web uses via Tailwind, so the two surfaces round the same way.
/// `--radius` is `0.625rem`; cards are `rounded-2xl`, controls `rounded-xl`.
///
/// Five steps only. Every rounded corner in the app must come from this list —
/// mixing ad-hoc values is what makes a screen read as unplanned.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double control = 14;
  static const double card = 20;
}

/// The 4pt vertical rhythm. Section gaps come from [section] so every band on
/// a page is spaced identically; ad-hoc `18.h` / `22.h` / `10.h` values are
/// what made the home feed look shuffled.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Page gutter, left and right.
  static const double gutter = 20;

  /// Gap between two top-level sections.
  static const double section = 28;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    // The web ships light-only (`color-scheme: only light`), so there is no
    // dark counterpart to mirror.
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.brandNavy,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        surface: AppColors.surface,
        onSurface: AppColors.foreground,
        outline: AppColors.border,
      ),
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.brandNavy,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.brandNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.brandNavy,
        ),
      ),
      // Cards separate from the page by fill, not by a stroke or an elevation.
      cardTheme: CardThemeData(
        color: AppColors.surfaceSoft,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSoft,
        side: BorderSide.none,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brandNavy,
        ),
        shape: const StadiumBorder(),
      ),
      // Borderless inputs: the tonal fill carries the affordance, and focus is
      // signalled by a ring rather than by a permanent outline. Every state
      // still returns a border object — swapping in `InputBorder.none` on some
      // states and an outline on others makes the field jump on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.mutedForeground,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(
            color: AppColors.destructive,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Secondary action. Still an OutlinedButton at every call site, but it
      // paints as a tonal fill so the UI carries no strokes; the accent tint
      // keeps it clearly subordinate to the solid primary button beside it.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentForeground,
          backgroundColor: AppColors.accent,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

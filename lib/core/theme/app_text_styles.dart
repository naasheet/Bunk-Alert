import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';

class AppTextStyles {
  static TextStyle displayHero(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 72,
        letterSpacing: -2.0,
        color: palette.textPrimary,
      );

  static TextStyle displayLarge(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 56,
        letterSpacing: -1.5,
        color: palette.textPrimary,
      );

  static TextStyle headingXL(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: -0.8,
        color: palette.textPrimary,
      );

  static TextStyle headingLarge(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 26,
        letterSpacing: -0.5,
        color: palette.textPrimary,
      );

  static TextStyle headingMedium(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.3,
        color: palette.textPrimary,
      );

  static TextStyle headingSmall(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      );

  static TextStyle bodyLarge(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: palette.textPrimary,
      );

  static TextStyle bodyMedium(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: palette.textPrimary,
      );

  static TextStyle bodySmall(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 13,
        color: palette.textSecondary,
      );

  static TextStyle labelLarge(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.3,
        color: palette.textPrimary,
      );

  static TextStyle labelMedium(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.3,
        color: palette.textPrimary,
      );

  static TextStyle labelSmall(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.8,
        color: palette.textSecondary,
      );

  static TextStyle caption(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 11,
        letterSpacing: 0.2,
        color: palette.textSecondary,
      );

  static TextStyle monoNumber(AppColorPalette palette) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: palette.textPrimary,
      );

  static TextTheme textTheme(AppColorPalette palette) => TextTheme(
        displayLarge: displayHero(palette),
        displayMedium: displayLarge(palette),
        displaySmall: headingXL(palette),
        headlineLarge: headingLarge(palette),
        headlineMedium: headingMedium(palette),
        headlineSmall: headingSmall(palette),
        titleLarge: headingLarge(palette),
        titleMedium: headingMedium(palette),
        titleSmall: headingSmall(palette),
        bodyLarge: bodyLarge(palette),
        bodyMedium: bodyMedium(palette),
        bodySmall: bodySmall(palette),
        labelLarge: labelLarge(palette),
        labelMedium: labelMedium(palette),
        labelSmall: labelSmall(palette),
      );

  const AppTextStyles._();
}

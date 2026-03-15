import 'package:flutter/material.dart';

abstract class AppColorPalette {
  Color get background;
  Color get surface;
  Color get surfaceElevated;
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get border;
  Color get safe;
  Color get safeSubtle;
  Color get danger;
  Color get dangerSubtle;
  Color get warning;
  Color get warningSubtle;
  Color get critical;
  Color get criticalSubtle;
  Color get chartLine;
  Color get chartFill;
}

class AppColors {
  static const AppColorPalette light = _AppLightColors();
  static const AppColorPalette dark = _AppDarkColors();

  const AppColors._();
}

class _AppLightColors implements AppColorPalette {
  const _AppLightColors();

  @override
  Color get background => const Color(0xFFFFFFFF);
  @override
  Color get surface => const Color(0xFFF8F8F8);
  @override
  Color get surfaceElevated => const Color(0xFFF0F0F0);
  @override
  Color get textPrimary => const Color(0xFF0D0D0D);
  @override
  Color get textSecondary => const Color(0xFF666666);
  @override
  Color get textTertiary => const Color(0xFFAAAAAA);
  @override
  Color get border => const Color(0xFFEBEBEB);
  @override
  Color get safe => const Color(0xFF4CAF72);
  @override
  Color get safeSubtle => const Color(0xFFEBF7F1);
  @override
  Color get danger => const Color(0xFFD95555);
  @override
  Color get dangerSubtle => const Color(0xFFFAECEC);
  @override
  Color get warning => const Color(0xFFD4924B);
  @override
  Color get warningSubtle => const Color(0xFFFDF3E7);
  @override
  Color get critical => const Color(0xFFC0392B);
  @override
  Color get criticalSubtle => const Color(0xFFFDECEB);
  @override
  Color get chartLine => const Color(0xFF2A2A2A);
  @override
  Color get chartFill => const Color(0xFFF0F0F0);
}

class _AppDarkColors implements AppColorPalette {
  const _AppDarkColors();

  @override
  Color get background => const Color(0xFF000000);
  @override
  Color get surface => const Color(0xFF111111);
  @override
  Color get surfaceElevated => const Color(0xFF1C1C1C);
  @override
  Color get textPrimary => const Color(0xFFF5F5F5);
  @override
  Color get textSecondary => const Color(0xFF888888);
  @override
  Color get textTertiary => const Color(0xFF555555);
  @override
  Color get border => const Color(0xFF2A2A2A);
  @override
  Color get safe => const Color(0xFF4CAF72);
  @override
  Color get safeSubtle => const Color(0xFF0A2015);
  @override
  Color get danger => const Color(0xFFD95555);
  @override
  Color get dangerSubtle => const Color(0xFF250D0D);
  @override
  Color get warning => const Color(0xFFD4924B);
  @override
  Color get warningSubtle => const Color(0xFF241608);
  @override
  Color get critical => const Color(0xFFC0392B);
  @override
  Color get criticalSubtle => const Color(0xFF300A09);
  @override
  Color get chartLine => const Color(0xFFF5F5F5);
  @override
  Color get chartFill => const Color(0xFF1C1C1C);
}

import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(
        palette: AppColors.light,
        brightness: Brightness.light,
      );

  static ThemeData get darkTheme => _buildTheme(
        palette: AppColors.dark,
        brightness: Brightness.dark,
      );

  static ThemeData _buildTheme({
    required AppColorPalette palette,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.chartLine,
      onPrimary: palette.background,
      secondary: palette.chartLine,
      onSecondary: palette.background,
      error: palette.danger,
      onError: palette.background,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      background: palette.background,
      onBackground: palette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Inter',
      textTheme: AppTextStyles.textTheme(palette),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 0.5,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.background.withOpacity(0),
        centerTitle: false,
        foregroundColor: palette.textPrimary,
        titleTextStyle: AppTextStyles.headingSmall(palette),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        hintStyle: AppTextStyles.caption(palette)
            .copyWith(color: palette.textTertiary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.chartLine,
          foregroundColor: palette.background,
          textStyle: AppTextStyles.labelLarge(palette),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.chartLine,
          foregroundColor: palette.background,
          textStyle: AppTextStyles.labelLarge(palette),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.surfaceElevated,
          foregroundColor: palette.textPrimary,
          textStyle: AppTextStyles.labelLarge(palette),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          textStyle: AppTextStyles.labelLarge(palette),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.surface,
        contentTextStyle:
            AppTextStyles.bodyMedium(palette).copyWith(color: palette.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
      ),
    );
  }

  const AppTheme._();
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_fonts.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.PRIMARY,
    scaffoldBackgroundColor: AppColors.NEUTRAL_95,
    colorScheme: const ColorScheme.light(
      primary: AppColors.PRIMARY,
      onPrimary: AppColors.WHITE,
      secondary: AppColors.SECONDARY,
      onSecondary: AppColors.WHITE,
      error: AppColors.TERTIARY_50,
      surface: AppColors.WHITE,
      onSurface: AppColors.NEUTRAL_10,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.PRIMARY,
      foregroundColor: AppColors.WHITE,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.TRANSPARENT,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.WHITE,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.MD),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.PRIMARY,
        foregroundColor: AppColors.WHITE,
        elevation: 0,
        shadowColor: AppColors.TRANSPARENT,
        surfaceTintColor: AppColors.TRANSPARENT,
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.XL,
          vertical: AppPadding.MD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.FULL),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        shadowColor: AppColors.TRANSPARENT,
        surfaceTintColor: AppColors.TRANSPARENT,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.FULL),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        shadowColor: AppColors.TRANSPARENT,
        surfaceTintColor: AppColors.TRANSPARENT,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.FULL),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: AppColors.TRANSPARENT,
        surfaceTintColor: AppColors.TRANSPARENT,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.FULL),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.WHITE,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppPadding.BASE,
        vertical: AppPadding.BASE,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.MD),
        borderSide: const BorderSide(color: AppColors.NEUTRAL_90),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.MD),
        borderSide: const BorderSide(color: AppColors.NEUTRAL_90),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.MD),
        borderSide: const BorderSide(color: AppColors.PRIMARY, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.MD),
        borderSide: const BorderSide(color: AppColors.TERTIARY_50),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.MD),
        borderSide: const BorderSide(color: AppColors.TERTIARY_50, width: 2),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.NEUTRAL_90,
      thickness: 1,
      space: 1,
    ),
  );
}

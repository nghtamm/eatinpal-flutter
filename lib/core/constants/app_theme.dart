import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.PRIMARY,
        scaffoldBackgroundColor: AppColors.BACKGROUND,
        colorScheme: const ColorScheme.light(
          primary: AppColors.PRIMARY,
          onPrimary: AppColors.TEXT_ON_PRIMARY,
          secondary: AppColors.SECONDARY,
          onSecondary: AppColors.TEXT_ON_PRIMARY,
          error: AppColors.ERROR,
          surface: AppColors.SURFACE,
          onSurface: AppColors.TEXT_PRIMARY,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.PRIMARY,
          foregroundColor: AppColors.TEXT_ON_PRIMARY,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: AppColors.CARD,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.PRIMARY,
            foregroundColor: AppColors.TEXT_ON_PRIMARY,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.SURFACE,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.DIVIDER),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.DIVIDER),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.PRIMARY,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.ERROR),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.DIVIDER,
          thickness: 1,
        ),
      );
}

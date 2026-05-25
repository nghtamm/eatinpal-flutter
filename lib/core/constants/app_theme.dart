import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_fonts.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

abstract final class AppTheme {
  // [THEME]
  static ThemeData get light => _build(_LIGHT_SCHEME);

  // [COLOR SCHEME]
  static const _LIGHT_SCHEME = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.PRIMARY,
    onPrimary: AppColors.WHITE,
    primaryContainer: AppColors.PRIMARY_SOFT,
    onPrimaryContainer: AppColors.PRIMARY_DARK,
    secondary: AppColors.SECONDARY,
    onSecondary: AppColors.WHITE,
    secondaryContainer: AppColors.SECONDARY_95,
    onSecondaryContainer: AppColors.SECONDARY_30,
    tertiary: AppColors.TERTIARY,
    onTertiary: AppColors.WHITE,
    tertiaryContainer: AppColors.TERTIARY_95,
    onTertiaryContainer: AppColors.TERTIARY_30,
    error: AppColors.ERROR,
    onError: AppColors.WHITE,
    errorContainer: AppColors.ERROR_SOFT,
    onErrorContainer: AppColors.TERTIARY_10,
    surface: AppColors.SURFACE,
    onSurface: AppColors.NEUTRAL_10,
    surfaceContainerHighest: AppColors.SURFACE_CARD,
    outline: AppColors.BORDER_SOFT,
    outlineVariant: AppColors.NEUTRAL_80,
    shadow: AppColors.SHADOW_SOFT,
    scrim: AppColors.SCRIM,
  );

  // [TYPOGRAPHY]
  static const _TEXT_THEME = TextTheme(
    displayLarge: AppTypography.DISPLAY_LARGE,
    displayMedium: AppTypography.DISPLAY_MEDIUM,
    displaySmall: AppTypography.DISPLAY_SMALL,
    headlineLarge: AppTypography.HEADLINE_LARGE,
    headlineMedium: AppTypography.HEADLINE_MEDIUM,
    headlineSmall: AppTypography.HEADLINE_SMALL,
    titleLarge: AppTypography.TITLE_LARGE,
    titleMedium: AppTypography.TITLE_MEDIUM,
    titleSmall: AppTypography.TITLE_SMALL,
    bodyLarge: AppTypography.BODY_LARGE,
    bodyMedium: AppTypography.BODY_MEDIUM,
    bodySmall: AppTypography.BODY_SMALL,
    labelLarge: AppTypography.LABEL_LARGE,
    labelMedium: AppTypography.LABEL_MEDIUM,
    labelSmall: AppTypography.LABEL_SMALL,
  );

  // [BORDER]
  static OutlineInputBorder _outline(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.BASE),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // [THEME BUILDER]
  static ThemeData _build(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: AppFonts.PRIMARY,
    textTheme: _TEXT_THEME,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: AppColors.TRANSPARENT,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: scheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: AppColors.TRANSPARENT,
            ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.FIELD_FILL,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppPadding.BASE,
        vertical: AppPadding.BASE,
      ),
      border: _outline(AppColors.BORDER_SOFT, 1),
      enabledBorder: _outline(AppColors.BORDER_SOFT, 1),
      focusedBorder: _outline(scheme.primary, 1.5),
      errorBorder: _outline(scheme.error, 1),
      focusedErrorBorder: _outline(scheme.error, 1.5),
      helperMaxLines: 3,
      errorMaxLines: 3,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.BORDER_SOFT,
      thickness: 1,
      space: 1,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_fonts.dart';

abstract final class AppTypography {
  // [DISPLAY] Short, high-emphasis text - hero banners, large numerals
  static const TextStyle DISPLAY_LARGE = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle DISPLAY_MEDIUM = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.25,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle DISPLAY_SMALL = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.NEUTRAL_10,
  );

  // [HEADLINE] Short, high-impact text - page titles, section headers, modals
  static const TextStyle HEADLINE_LARGE = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle HEADLINE_MEDIUM = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle HEADLINE_SMALL = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.NEUTRAL_10,
  );

  // [TITLE] Medium-emphasis short text - card/list/dialog titles, app bar
  static const TextStyle TITLE_LARGE = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle TITLE_MEDIUM = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.15,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle TITLE_SMALL = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.NEUTRAL_10,
  );

  // [BODY] Long-form reading content - paragraphs, descriptions, articles
  static const TextStyle BODY_LARGE = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle BODY_MEDIUM = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle BODY_SMALL = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
    color: AppColors.NEUTRAL_10,
  );

  // [LABEL] Call-to-action and UI text - buttons, chips, tabs, form labels
  static const TextStyle LABEL_LARGE = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle LABEL_MEDIUM = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppColors.NEUTRAL_10,
  );

  static const TextStyle LABEL_SMALL = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppColors.NEUTRAL_10,
  );
}

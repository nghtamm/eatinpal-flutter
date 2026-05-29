import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_fonts.dart';

abstract final class AppTypography {
  static const Color _BASE_TEXT_COLOR = AppColors.TEXT_PRIMARY;

  // [DISPLAY] Short, high-emphasis text - hero banners, large numerals
  static const TextStyle DISPLAY_LARGE = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -0.25,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle DISPLAY_MEDIUM = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.16,
    letterSpacing: 0,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle DISPLAY_SMALL = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.22,
    letterSpacing: 0,
    color: _BASE_TEXT_COLOR,
  );

  // [HEADLINE] Short, high-impact text - page titles, section headers, modals
  static const TextStyle HEADLINE_LARGE = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle HEADLINE_MEDIUM = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: 0,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle HEADLINE_SMALL = TextStyle(
    fontFamily: AppFonts.DISPLAY,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0,
    color: _BASE_TEXT_COLOR,
  );

  // [TITLE] Medium-emphasis short text - card/list/dialog titles, app bar
  static const TextStyle TITLE_LARGE = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: 0,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle TITLE_MEDIUM = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle TITLE_SMALL = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
    color: _BASE_TEXT_COLOR,
  );

  // [BODY] Long-form reading content - paragraphs, descriptions, articles
  static const TextStyle BODY_LARGE = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle BODY_MEDIUM = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle BODY_SMALL = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
    color: _BASE_TEXT_COLOR,
  );

  // [LABEL] Call-to-action and UI text - buttons, chips, tabs, form labels
  static const TextStyle LABEL_LARGE = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle LABEL_MEDIUM = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
    color: _BASE_TEXT_COLOR,
  );

  static const TextStyle LABEL_SMALL = TextStyle(
    fontFamily: AppFonts.PRIMARY,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
    color: _BASE_TEXT_COLOR,
  );
}

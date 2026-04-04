import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';

abstract final class AppTypography {
  static const TextStyle HEADING_1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle HEADING_2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle HEADING_3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle SUBTITLE_1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle SUBTITLE_2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle BODY_1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle BODY_2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle CAPTION = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_SECONDARY,
  );

  static const TextStyle BUTTON = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_ON_PRIMARY,
  );

  static const TextStyle LABEL = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.TEXT_SECONDARY,
  );

  static const TextStyle OVERLINE = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_HINT,
    letterSpacing: 1.5,
  );
}

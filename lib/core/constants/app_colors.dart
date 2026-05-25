import 'package:flutter/material.dart';

abstract final class AppColors {
  // [PRIMARY]
  static const Color PRIMARY = Color(0xFF34C77B);
  static const Color PRIMARY_DARK = Color(0xFF1FA866);
  static const Color PRIMARY_SOFT = Color(0xFFDCFCE7);
  static const Color PRIMARY_SOFT_2 = Color(0xFFE9FBEF);
  static const Color PRIMARY_10 = Color(0xFF052311);
  static const Color PRIMARY_20 = Color(0xFF083B1F);
  static const Color PRIMARY_30 = Color(0xFF0F5731);
  static const Color PRIMARY_40 = Color(0xFF157B47);
  static const Color PRIMARY_50 = PRIMARY_DARK;
  static const Color PRIMARY_60 = PRIMARY;
  static const Color PRIMARY_70 = Color(0xFF5BD495);
  static const Color PRIMARY_80 = Color(0xFF86E5B4);
  static const Color PRIMARY_90 = Color(0xFFBAF1D1);
  static const Color PRIMARY_95 = PRIMARY_SOFT;

  // [SECONDARY]
  static const Color SECONDARY = Color(0xFF6A9B81);
  static const Color SECONDARY_10 = Color(0xFF04140C);
  static const Color SECONDARY_20 = Color(0xFF102218);
  static const Color SECONDARY_30 = Color(0xFF1F3826);
  static const Color SECONDARY_40 = Color(0xFF305037);
  static const Color SECONDARY_50 = Color(0xFF4A6B53);
  static const Color SECONDARY_60 = SECONDARY;
  static const Color SECONDARY_70 = Color(0xFF8FB6A2);
  static const Color SECONDARY_80 = Color(0xFFB0CFBE);
  static const Color SECONDARY_90 = Color(0xFFD1E5D8);
  static const Color SECONDARY_95 = Color(0xFFE8F2EC);

  // [TERTIARY]
  static const Color TERTIARY = Color(0xFFF87171);
  static const Color TERTIARY_10 = Color(0xFF2A0507);
  static const Color TERTIARY_20 = Color(0xFF4D0C10);
  static const Color TERTIARY_30 = Color(0xFF791C20);
  static const Color TERTIARY_40 = Color(0xFFA23036);
  static const Color TERTIARY_50 = Color(0xFFC9474D);
  static const Color TERTIARY_60 = Color(0xFFE5605F);
  static const Color TERTIARY_70 = TERTIARY;
  static const Color TERTIARY_80 = Color(0xFFFBA1A1);
  static const Color TERTIARY_90 = Color(0xFFFDCBCB);
  static const Color TERTIARY_95 = Color(0xFFFFEAEA);

  // [NEUTRAL]
  static const Color NEUTRAL_10 = Color(0xFF161D19);
  static const Color NEUTRAL_20 = Color(0xFF2B322D);
  static const Color NEUTRAL_30 = Color(0xFF414843);
  static const Color NEUTRAL_40 = Color(0xFF59605B);
  static const Color NEUTRAL_50 = Color(0xFF717973);
  static const Color NEUTRAL_60 = Color(0xFF8B938C);
  static const Color NEUTRAL_70 = Color(0xFFA5ADA7);
  static const Color NEUTRAL_80 = Color(0xFFC1C8C2);
  static const Color NEUTRAL_90 = Color(0xFFDDE4DD);
  static const Color NEUTRAL_95 = Color(0xFFEBF3EB);

  // [TEXT]
  static const Color TEXT_PRIMARY = NEUTRAL_10;
  static const Color TEXT_SECONDARY = NEUTRAL_40;
  static const Color TEXT_TERTIARY = NEUTRAL_60;

  // [SEMANTIC]
  static const Color SUCCESS = Color(0xFF22C55E);
  static const Color SUCCESS_SOFT = Color(0xFFDCFCE7);
  static const Color WARNING = Color(0xFFF59E0B);
  static const Color WARNING_SOFT = Color(0xFFFEF3C7);
  static const Color ERROR = Color(0xFFEF4444);
  static const Color ERROR_SOFT = Color(0xFFFEE2E2);
  static const Color INFO = Color(0xFF3B82F6);
  static const Color INFO_SOFT = Color(0xFFDBEAFE);

  // [SURFACE]
  static const Color SURFACE = Color(0xFFF4F9F4);
  static const Color SURFACE_CARD = Color(0xFFFFFFFF);
  static const Color FIELD_FILL = Color(0xFFF1F6F2);
  static const Color BORDER_SOFT = Color(0xFFE2E8E3);
  static const Color BORDER_STRONG = NEUTRAL_80;
  static const Color SHADOW_SOFT = Color(0x3334C77B);

  // [COMMON]
  static const Color BLACK = Color(0xFF000000);
  static const Color WHITE = Color(0xFFFFFFFF);
  static const Color TRANSPARENT = Color(0x00000000);
  static const Color SCRIM = Color(0x66000000);
}

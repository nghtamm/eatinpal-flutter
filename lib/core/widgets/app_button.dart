import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

enum AppButtonVariant { PRIMARY, SECONDARY, DANGER }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.PRIMARY,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, bgDisabled) = switch (variant) {
      AppButtonVariant.PRIMARY => (
        AppColors.PRIMARY,
        AppColors.WHITE,
        AppColors.PRIMARY_80,
      ),
      AppButtonVariant.SECONDARY => (
        AppColors.NEUTRAL_90,
        AppColors.NEUTRAL_10,
        AppColors.NEUTRAL_80,
      ),
      AppButtonVariant.DANGER => (
        AppColors.TERTIARY_50,
        AppColors.WHITE,
        AppColors.TERTIARY_80,
      ),
    };

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bgDisabled,
          elevation: 0,
          shadowColor: AppColors.TRANSPARENT,
          surfaceTintColor: AppColors.TRANSPARENT,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.FULL),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTypography.LABEL_LARGE.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: fg,
          ),
        ),
      ),
    );
  }
}

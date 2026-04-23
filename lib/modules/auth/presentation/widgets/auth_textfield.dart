import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

class AuthTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final String? helperText;
  final AutovalidateMode autovalidateMode;

  const AuthTextField({
    super.key,
    this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.helperText,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.SM);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.LABEL_MEDIUM.copyWith(
              letterSpacing: 1.2,
              color: AppColors.NEUTRAL_10,
            ),
          ),
          SIZED_BOX_H8,
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autovalidateMode: autovalidateMode,
          validator: validator,
          style: AppTypography.BODY_LARGE.copyWith(
            fontFeatures: const [FontFeature('calt', 0)],
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.BODY_LARGE.copyWith(
              color: AppColors.NEUTRAL_60,
            ),
            filled: true,
            fillColor: AppColors.NEUTRAL_90,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppPadding.BASE,
              vertical: AppPadding.BASE,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppColors.PRIMARY, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppColors.TERTIARY_50),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.TERTIARY_50,
                width: 2,
              ),
            ),
            helperText: helperText,
            helperStyle: AppTypography.BODY_SMALL.copyWith(
              color: AppColors.NEUTRAL_40,
            ),
            helperMaxLines: 3,
            errorMaxLines: 3,
            errorStyle: AppTypography.BODY_SMALL.copyWith(
              color: AppColors.TERTIARY_50,
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

class PasswordStrength extends StatelessWidget {
  final TextEditingController controller;

  const PasswordStrength({super.key, required this.controller});

  static const _BARS = 4;

  int _score(String value) {
    if (value.isEmpty) return 0;

    int scr = 0;
    if (value.length >= 8) scr++;

    if (RegExp(r'[A-Z]').hasMatch(value)) scr++;
    if (RegExp(r'[a-z]').hasMatch(value)) scr++;
    if (RegExp(r'\d').hasMatch(value)) scr++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) scr++;

    return scr;
  }

  ({int filled, Color color, String label}) _profile(int score) {
    if (score <= 1) {
      return (filled: 1, color: AppColors.TERTIARY_50, label: 'Weak');
    } else if (score == 2) {
      return (filled: 2, color: AppColors.WARNING, label: 'Medium');
    } else if (score == 3 || score == 4) {
      return (filled: 3, color: AppColors.PRIMARY, label: 'Good');
    } else {
      return (filled: 4, color: AppColors.PRIMARY_DARK, label: 'Strong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final value = controller.text;
        if (value.isEmpty) return SPACE_ZERO;

        final p = _profile(_score(value));

        return Padding(
          padding: const EdgeInsets.only(top: AppPadding.MD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(_BARS, (idx) {
                  final isFilled = idx < p.filled;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: idx == _BARS - 1 ? AppPadding.NONE : 6,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 6,
                        decoration: BoxDecoration(
                          color: isFilled ? p.color : AppColors.BORDER_SOFT,
                          borderRadius: BorderRadius.circular(AppRadius.FULL),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SIZED_BOX_H6,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Password strength',
                    style: AppTypography.BODY_SMALL.copyWith(
                      color: AppColors.NEUTRAL_40,
                    ),
                  ),
                  Text(
                    p.label,
                    style: AppTypography.BODY_SMALL.copyWith(
                      color: p.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

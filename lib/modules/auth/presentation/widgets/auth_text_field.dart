import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.LABEL),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: AppTypography.BODY_1,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.BODY_1.copyWith(
              color: AppColors.TEXT_HINT,
            ),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.TEXT_HINT,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

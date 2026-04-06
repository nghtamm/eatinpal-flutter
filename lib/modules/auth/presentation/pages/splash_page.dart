import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppColors.PRIMARY,
            ),
            SIZED_BOX_H16,
            Text(
              'EatinPal',
              style: AppTypography.HEADING_1.copyWith(
                color: AppColors.PRIMARY,
              ),
            ),
            SIZED_BOX_H24,
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

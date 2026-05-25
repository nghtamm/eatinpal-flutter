import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.NEUTRAL_95,
      appBar: AppBar(
        backgroundColor: AppColors.NEUTRAL_95,
        title: const Text('Home', style: AppTypography.TITLE_LARGE),
      ),
      body: const Center(
        child: Text('Welcome to EatinPal', style: AppTypography.DISPLAY_MEDIUM),
      ),
    );
  }
}

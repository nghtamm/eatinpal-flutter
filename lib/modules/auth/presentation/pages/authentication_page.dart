import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/widgets/app_button.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  static const _BANNER_HEIGHT = 280.0;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.top;
    final bannerHeight = _BANNER_HEIGHT + inset;

    return Scaffold(
      backgroundColor: AppColors.NEUTRAL_95,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: _buildBanner(),
          ),
          Positioned(
            top: bannerHeight - AppRadius.XL,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.NEUTRAL_95,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.XL),
                ),
              ),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      color: AppColors.NEUTRAL_10,
      child: Image.asset(
        'assets/images/welcome_banner.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          SIZED_BOX_H16,
          _buildTitle(),
          SIZED_BOX_H12,
          _buildSubtitle(),
          SIZED_BOX_H24,
          _buildRegisterButton(context),
          SIZED_BOX_H12,
          _buildLoginButton(context),
          SIZED_BOX_H20,
          _buildDivider(),
          SIZED_BOX_H20,
          _buildSocials(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        const Icon(Icons.eco, color: AppColors.PRIMARY, size: 26),
        SIZED_BOX_W8,
        Text(
          'EATINPAL',
          style: AppTypography.HEADLINE_MEDIUM.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.PRIMARY,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      'FUEL\nYOUR\nJOURNEY',
      style: AppTypography.DISPLAY_LARGE.copyWith(fontSize: 44, height: 1.05),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'A simple way to track what you eat and slowly shape better habits around it.',
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return AppButton(
      label: 'REGISTER',
      onPressed: () => context.push(RoutePaths.REGISTER),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return AppButton(
      label: 'LOGIN',
      variant: AppButtonVariant.SECONDARY,
      onPressed: () => context.push(RoutePaths.LOGIN),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.NEUTRAL_80)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.MD),
          child: Text(
            'OR CONTINUE WITH',
            style: AppTypography.LABEL_SMALL.copyWith(
              letterSpacing: 1.2,
              color: AppColors.NEUTRAL_40,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.NEUTRAL_80)),
      ],
    );
  }

  Widget _buildSocials() {
    return Row(
      children: [
        Expanded(
          child: _socialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            onTap: () {},
          ),
        ),
        SIZED_BOX_W12,
        Expanded(
          child: _socialButton(icon: Icons.apple, label: 'Apple', onTap: () {}),
        ),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.NEUTRAL_10, size: 22),
        label: Text(label, style: AppTypography.LABEL_LARGE),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.WHITE,
          side: const BorderSide(color: AppColors.NEUTRAL_90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.FULL),
          ),
        ),
      ),
    );
  }
}

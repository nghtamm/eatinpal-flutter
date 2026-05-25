import 'package:eatinpal/core/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/widgets/app_button.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  static const _BANNER_HEIGHT = 320;
  static const _SHEET_OVERLAP = 40;

  @override
  Widget build(BuildContext context) {
    final inset = context.padding.top;
    final bannerHeight = _BANNER_HEIGHT + inset;

    return Scaffold(
      backgroundColor: AppColors.SURFACE,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: bannerHeight,
            child: _banner(inset),
          ),
          Positioned(
            left: 0,
            top: bannerHeight - _SHEET_OVERLAP,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.SURFACE,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.XL),
                ),
              ),
              child: _content(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(double inset) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.PRIMARY_80, AppColors.PRIMARY],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -60,
            top: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.WHITE.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 160,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.WHITE.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: inset + 60,
            right: 32,
            child: Transform.rotate(
              angle: -0.35,
              child: Icon(
                Icons.eco,
                color: AppColors.WHITE.withValues(alpha: 0.73),
                size: 28,
              ),
            ),
          ),
          Positioned(
            left: 40,
            top: inset + 200,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(
                Icons.eco,
                color: AppColors.WHITE.withValues(alpha: 0.60),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _logo(),
          SIZED_BOX_H20,
          _title(),
          SIZED_BOX_H12,
          _subtitle(),
          SIZED_BOX_H24,
          _registerButton(context),
          SIZED_BOX_H12,
          _loginButton(context),
          SIZED_BOX_H20,
          _divider(),
          SIZED_BOX_H20,
          _socials(),
        ],
      ),
    );
  }

  Widget _logo() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.PRIMARY_SOFT,
            borderRadius: BorderRadius.circular(AppRadius.MD),
          ),
          child: const Icon(Icons.eco, color: AppColors.PRIMARY_DARK, size: 18),
        ),
        SIZED_BOX_W8,
        Text(
          'EATINPAL',
          style: AppTypography.HEADLINE_MEDIUM.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.PRIMARY_DARK,
          ),
        ),
      ],
    );
  }

  Widget _title() {
    return Text(
      'FUEL\nYOUR\nJOURNEY',
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 46,
        height: 1.0,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    return Text(
      'A simple way to track what you eat and slowly shape better habits around it.',
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }

  Widget _registerButton(BuildContext context) {
    return AppButton(
      label: 'REGISTER',
      onPressed: () => context.push(RoutePaths.REGISTER),
    );
  }

  Widget _loginButton(BuildContext context) {
    return AppButton(
      label: 'LOGIN',
      variant: AppButtonVariant.SECONDARY,
      onPressed: () => context.push(RoutePaths.LOGIN),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.BORDER_SOFT)),
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
        const Expanded(child: Divider(color: AppColors.BORDER_SOFT)),
      ],
    );
  }

  Widget _socials() {
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
          side: const BorderSide(color: AppColors.BORDER_SOFT),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.FULL),
          ),
        ),
      ),
    );
  }
}

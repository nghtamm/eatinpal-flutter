import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

enum AppSnackbarType { SUCCESS, WARNING, ERROR }

abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.SUCCESS,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_build(context, message, type, duration));
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.SUCCESS);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.WARNING);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.ERROR);

  static SnackBar _build(
    BuildContext context,
    String message,
    AppSnackbarType type,
    Duration duration,
  ) {
    final (icon, accent) = switch (type) {
      AppSnackbarType.SUCCESS => (Icons.check_circle, AppColors.PRIMARY),
      AppSnackbarType.WARNING => (Icons.warning_rounded, AppColors.WARNING),
      AppSnackbarType.ERROR => (Icons.error, AppColors.TERTIARY_50),
    };

    return SnackBar(
      backgroundColor: AppColors.TRANSPARENT,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.all(AppPadding.BASE),
      padding: EdgeInsets.zero,
      content: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => FractionalTranslation(
          translation: Offset(0, value),
          child: Opacity(opacity: 1 - value, child: child),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.MD),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.MD),
            child: ColoredBox(
              color: accent,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  color: AppColors.WHITE,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.MD),
                    topRight: Radius.circular(AppRadius.MD),
                    bottomLeft: Radius.circular(AppRadius.MD - 4),
                    bottomRight: Radius.circular(AppRadius.MD - 4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.BASE),
                  child: Row(
                    children: [
                      Icon(icon, color: accent, size: 24),
                      SIZED_BOX_W12,
                      Expanded(
                        child: Text(
                          message,
                          style: AppTypography.BODY_MEDIUM.copyWith(
                            color: AppColors.NEUTRAL_10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SIZED_BOX_W8,
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppPadding.XS,
                            AppPadding.XS,
                            AppPadding.NONE,
                            AppPadding.XS,
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColors.NEUTRAL_40,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

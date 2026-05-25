import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/core/constants/app_colors.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color backgroundColor;
  final bool centerTitle;

  const BasicAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor = AppColors.SURFACE,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: AppColors.TRANSPARENT,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      title: title,
      actions: actions,
      leading: leading ?? _defaultBackButton(context),
    );
  }

  Widget _defaultBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.chevron_left,
        size: 28,
        color: AppColors.NEUTRAL_10,
      ),
      onPressed: () => context.pop(),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/widgets/app_button.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
import 'package:eatinpal/core/widgets/basic_appbar.dart';
import 'package:eatinpal/core/widgets/loading_overlay.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_event.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_state.dart';

typedef VerifyEmailArgs = ({String email, String password, bool autoResend});

class VerifyEmailPage extends StatelessWidget {
  final VerifyEmailArgs? args;

  const VerifyEmailPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: _VerifyEmailView(args: args),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  final VerifyEmailArgs? args;

  const _VerifyEmailView({required this.args});

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  int _cooldown = 0;
  Timer? _timer;

  String get _email => widget.args?.email ?? '';
  String get _password => widget.args?.password ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.args?.autoResend == true && _email.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestResend());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _requestResend() {
    if (_email.isEmpty || _cooldown > 0) return;
    context.read<AuthBloc>().add(AuthResendVerificationRequested(_email));
    _startCooldown();
  }

  void _verifyAndLogin() {
    if (_email.isEmpty || _password.isEmpty) {
      AppSnackbar.error(context, 'Missing credentials, please log in again');
      return;
    }
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(email: _email, password: _password),
    );
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown = _cooldown - 1);
      if (_cooldown <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onStateChanged,
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) =>
            (prev is AuthLoading) != (curr is AuthLoading),
        builder: (_, state) => LoadingOverlay(
          isLoading: state is AuthLoading,
          child: Scaffold(
            backgroundColor: AppColors.SURFACE,
            appBar: const BasicAppBar(),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: _content()),
                  _bottom(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      context.go(RoutePaths.VERIFICATION_SUCCESS);
    } else if (state is AuthRequiresVerification) {
      AppSnackbar.warning(context, state.message);
    } else if (state is AuthSuccess) {
      AppSnackbar.success(context, state.message);
    } else if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
    }
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.XL,
        AppPadding.XL,
        AppPadding.XL,
        AppPadding.NONE,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _icon(),
          SIZED_BOX_H24,
          _title(),
          SIZED_BOX_H12,
          _subtitle(),
          SIZED_BOX_H32,
          _timelineCard(),
        ],
      ),
    );
  }

  Widget _icon() {
    return Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: AppColors.PRIMARY_SOFT_2,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.mark_email_unread_outlined,
          color: AppColors.PRIMARY_DARK,
          size: 92,
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      'VERIFY\nYOUR EMAIL',
      textAlign: TextAlign.center,
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 40,
        height: 1.0,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    final email = _email.isEmpty ? 'your inbox' : _email;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.LG),
      child: Text(
        'Check your inbox and tap the link we just sent to $email',
        textAlign: TextAlign.center,
        style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
      ),
    );
  }

  Widget _timelineCard() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.LG),
      decoration: BoxDecoration(
        color: AppColors.WHITE,
        borderRadius: BorderRadius.circular(AppRadius.BASE),
        border: Border.all(color: AppColors.BORDER_SOFT),
      ),
      child: Column(
        children: [
          _step(
            icon: Icons.send_outlined,
            title: 'Email sent',
            desc: "We've delivered the link to your inbox.",
            state: _StepState.DONE,
            showConnector: true,
          ),
          _step(
            icon: Icons.mark_email_unread_outlined,
            title: 'Open the email',
            desc: 'Tap the verification button inside.',
            state: _StepState.ACTIVE,
            showConnector: true,
          ),
          _step(
            icon: Icons.check,
            title: "You're in",
            desc: "We'll log you in automatically.",
            state: _StepState.TODO,
            showConnector: false,
          ),
        ],
      ),
    );
  }

  Widget _step({
    required IconData icon,
    required String title,
    required String desc,
    required _StepState state,
    required bool showConnector,
  }) {
    final isDone = state == _StepState.DONE;
    final isActive = state == _StepState.ACTIVE;

    final dotFill = isDone
        ? AppColors.PRIMARY
        : isActive
        ? AppColors.PRIMARY_SOFT
        : AppColors.SURFACE;
    final dotBorder = isDone || isActive
        ? AppColors.PRIMARY
        : AppColors.BORDER_SOFT;
    final iconColor = isDone
        ? AppColors.WHITE
        : isActive
        ? AppColors.PRIMARY_DARK
        : AppColors.NEUTRAL_60;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: dotFill,
                shape: BoxShape.circle,
                border: Border.all(color: dotBorder, width: isActive ? 2 : 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 24,
                color: isDone ? AppColors.PRIMARY : AppColors.BORDER_SOFT,
              ),
          ],
        ),
        SIZED_BOX_W12,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: showConnector ? AppPadding.SM : AppPadding.NONE,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SIZED_BOX_H4,
                Text(
                  title,
                  style: AppTypography.BODY_MEDIUM.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SIZED_BOX_H2,
                Text(
                  desc,
                  style: AppTypography.BODY_SMALL.copyWith(
                    color: AppColors.NEUTRAL_40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        children: [
          _resendLink(),
          SIZED_BOX_H16,
          AppButton(
            label: "I'VE VERIFIED",
            onPressed: _verifyAndLogin,
            height: 56,
          ),
        ],
      ),
    );
  }

  Widget _resendLink() {
    final disabled = _cooldown > 0;
    final label = disabled ? 'Resend (${_cooldown}s)' : 'Resend';
    final color = disabled ? AppColors.NEUTRAL_60 : AppColors.NEUTRAL_10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't get the email? ",
          style: AppTypography.BODY_MEDIUM.copyWith(
            color: AppColors.NEUTRAL_40,
          ),
        ),
        GestureDetector(
          onTap: disabled ? null : _requestResend,
          child: Text(
            label,
            style: AppTypography.BODY_MEDIUM.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

enum _StepState { DONE, ACTIVE, TODO }

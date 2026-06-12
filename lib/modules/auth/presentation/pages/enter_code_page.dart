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
import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_event.dart';
import '../bloc/forgot_password_state.dart';
import '../widgets/otp_input.dart';

class EnterCodePage extends StatelessWidget {
  final String? email;

  const EnterCodePage({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<ForgotPasswordBloc>(),
      child: _EnterCodeView(email: email),
    );
  }
}

class _EnterCodeView extends StatefulWidget {
  final String? email;

  const _EnterCodeView({required this.email});

  @override
  State<_EnterCodeView> createState() => _EnterCodeViewState();
}

class _EnterCodeViewState extends State<_EnterCodeView> {
  String _otp = '';
  int _cooldown = 0;
  Timer? _timer;

  String get _email => widget.email ?? '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _resend() {
    if (_cooldown > 0) return;
    context.read<ForgotPasswordBloc>().add(ForgotPasswordRequested(_email));
  }

  void _verify() {
    if (_otp.length < 6) {
      AppSnackbar.error(context, 'Enter the 6-digit code');
      return;
    }
    context.read<ForgotPasswordBloc>().add(
      OTPSubmitted(email: _email, otp: _otp),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: _onStateChanged,
      child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
        buildWhen: (prev, curr) =>
            (prev is ForgotPasswordLoading) != (curr is ForgotPasswordLoading),
        builder: (_, state) => LoadingOverlay(
          isLoading: state is ForgotPasswordLoading,
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

  void _onStateChanged(BuildContext context, ForgotPasswordState state) {
    if (state is OTPVerified) {
      context.pushReplacement(RoutePaths.RESET_PASSWORD, extra: _email);
    } else if (state is OTPSent) {
      AppSnackbar.info(context, state.message);
      _startCooldown();
    } else if (state is ForgotPasswordFailure) {
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
          OTPInput(onChanged: (value) => setState(() => _otp = value)),
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
          Icons.verified_user_outlined,
          color: AppColors.PRIMARY_DARK,
          size: 72,
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      'ENTER\nCODE',
      textAlign: TextAlign.center,
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 40,
        height: 1.0,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    final target = _email.isEmpty ? 'your email' : _email;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.LG),
      child: Text(
        'Enter the 6-digit code we sent to $target',
        textAlign: TextAlign.center,
        style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
      ),
    );
  }

  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        children: [
          _resendLink(),
          SIZED_BOX_H16,
          AppButton(label: 'VERIFY', onPressed: _verify, height: 56),
        ],
      ),
    );
  }

  Widget _resendLink() {
    final isDisabled = _cooldown > 0;
    final label = isDisabled ? 'Resend (${_cooldown}s)' : 'Resend';
    final color = isDisabled ? AppColors.NEUTRAL_60 : AppColors.NEUTRAL_10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't get the code? ",
          style: AppTypography.BODY_MEDIUM.copyWith(
            color: AppColors.NEUTRAL_40,
          ),
        ),
        GestureDetector(
          onTap: isDisabled ? null : _resend,
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

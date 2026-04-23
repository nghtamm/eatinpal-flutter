import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/widgets/app_button.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
import 'package:eatinpal/core/widgets/basic_appbar.dart';
import 'package:eatinpal/core/widgets/loading_overlay.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_event.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_state.dart';

class VerifyEmailPage extends StatelessWidget {
  final String? email;

  const VerifyEmailPage({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: _VerifyEmailView(email: email),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  final String? email;

  const _VerifyEmailView({required this.email});

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  // [STATE]
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestResend());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _requestResend() {
    if (widget.email == null || _cooldown > 0) return;
    context.read<AuthBloc>().add(
      AuthResendVerificationRequested(widget.email!),
    );
    _startCooldown();
  }

  void _verifiedLogin() {
    context.read<AuthBloc>().add(const AuthVerifiedLoginRequested());
  }

  Future<void> _openVerificationSuccess() async {
    final token = await sl<LocalStorage>().verificationToken;
    if (!mounted) return;
    context.push(RoutePaths.VERIFICATION_SUCCESS, extra: token);
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
            backgroundColor: AppColors.NEUTRAL_95,
            appBar: const BasicAppBar(),
            floatingActionButton: FloatingActionButton(
              backgroundColor: AppColors.PRIMARY,
              foregroundColor: AppColors.WHITE,
              onPressed: _openVerificationSuccess,
              child: const Icon(Icons.check),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildContent()),
                  _buildBottom(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      AppSnackbar.success(context, state.message);
    } else if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
    }
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.XL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SIZED_BOX_H32,
          _buildIcon(),
          SIZED_BOX_H32,
          _buildTitle(),
          SIZED_BOX_H12,
          _buildSubtitle(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return const Icon(
      Icons.mark_email_unread_outlined,
      color: AppColors.PRIMARY,
      size: 96,
    );
  }

  Widget _buildTitle() {
    return Text(
      'VERIFY\nYOUR EMAIL',
      textAlign: TextAlign.center,
      style: AppTypography.DISPLAY_LARGE.copyWith(fontSize: 40, height: 1.05),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Check your inbox and follow the link we just sent to verify your email.',
      textAlign: TextAlign.center,
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        children: [
          _buildResendLink(),
          SIZED_BOX_H12,
          AppButton(
            label: "I'VE VERIFIED",
            onPressed: _verifiedLogin,
            height: 56,
          ),
        ],
      ),
    );
  }

  Widget _buildResendLink() {
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

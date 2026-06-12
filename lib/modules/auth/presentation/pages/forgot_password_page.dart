import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/helpers/validators.dart';
import 'package:eatinpal/core/widgets/app_button.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
import 'package:eatinpal/core/widgets/basic_appbar.dart';
import 'package:eatinpal/core/widgets/loading_overlay.dart';
import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_event.dart';
import '../bloc/forgot_password_state.dart';
import '../widgets/auth_textfield.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<ForgotPasswordBloc>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordRequested(_emailController.text.trim()),
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
              child: Form(
                key: _formKey,
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
      ),
    );
  }

  void _onStateChanged(BuildContext context, ForgotPasswordState state) {
    if (state is OTPSent) {
      AppSnackbar.success(context, state.message);
      context.pushReplacement(
        RoutePaths.VERIFY_OTP,
        extra: _emailController.text.trim(),
      );
    } else if (state is ForgotPasswordFailure) {
      AppSnackbar.error(context, state.message);
    }
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.XL,
        AppPadding.LG,
        AppPadding.XL,
        AppPadding.NONE,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(),
          SIZED_BOX_H12,
          _subtitle(),
          SIZED_BOX_H32,
          AuthTextField(
            label: 'EMAIL ADDRESS',
            hint: 'jane@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return Text(
      'FORGOT\nPASSWORD',
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 44,
        height: 1.0,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    return Text(
      "Enter your email and we'll send you a code to reset your password.",
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }

  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: AppButton(label: 'SEND CODE', onPressed: _submit, height: 56),
    );
  }
}

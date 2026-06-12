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
import '../widgets/password_strength.dart';

class NewPasswordPage extends StatelessWidget {
  final String? email;

  const NewPasswordPage({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<ForgotPasswordBloc>(),
      child: _NewPasswordView(email: email),
    );
  }
}

class _NewPasswordView extends StatefulWidget {
  final String? email;

  const _NewPasswordView({required this.email});

  @override
  State<_NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<_NewPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String get _email => widget.email ?? '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
      ResetSubmitted(email: _email, password: _passwordController.text),
    );
  }

  String? _confirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
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
    if (state is ResetDone) {
      AppSnackbar.success(context, state.message);
      context.go(RoutePaths.LOGIN);
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
            label: 'NEW PASSWORD',
            hint: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: Validators.password,
            helperText:
                'At least 8 characters, with 1 uppercase, 1 lowercase, 1 number and 1 special character.',
            suffix: _eye(
              obscure: _obscurePassword,
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          PasswordStrength(controller: _passwordController),
          SIZED_BOX_H20,
          AuthTextField(
            label: 'CONFIRM PASSWORD',
            hint: '••••••••',
            controller: _confirmController,
            obscureText: _obscureConfirm,
            validator: _confirm,
            suffix: _eye(
              obscure: _obscureConfirm,
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eye({required bool obscure, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.MD),
        child: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: AppColors.NEUTRAL_40,
          size: 22,
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      'NEW\nPASSWORD',
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 44,
        height: 1.0,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    return Text(
      'Create a new password for your account.',
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }

  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: AppButton(label: 'RESET PASSWORD', onPressed: _submit, height: 56),
    );
  }
}

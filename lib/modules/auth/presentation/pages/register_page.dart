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
import 'package:eatinpal/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_event.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_state.dart';
import 'package:eatinpal/modules/auth/presentation/widgets/auth_textfield.dart';
import 'package:eatinpal/modules/auth/presentation/widgets/password_strength.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<AuthBloc>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  // [KEY]
  final _formKey = GlobalKey<FormState>();

  // [CONTROLLER]
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // [STATE]
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthRegisterSubmitted(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
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

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
    } else if (state is AuthSuccess) {
      AppSnackbar.success(context, state.message);
      context.pushReplacement(
        RoutePaths.VERIFY_EMAIL,
        extra: (
          email: _emailController.text.trim(),
          password: _passwordController.text,
          autoResend: false,
        ),
      );
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
            label: 'FULL NAME',
            hint: 'Jane Doe',
            controller: _nameController,
            keyboardType: TextInputType.name,
            validator: Validators.name,
          ),
          SIZED_BOX_H20,
          AuthTextField(
            label: 'EMAIL ADDRESS',
            hint: 'jane@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          SIZED_BOX_H20,
          AuthTextField(
            label: 'PASSWORD',
            hint: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: Validators.password,
            helperText:
                'At least 8 characters, with 1 uppercase, 1 lowercase, 1 number and 1 special character.',
            suffix: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.MD),
                child: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.NEUTRAL_40,
                  size: 22,
                ),
              ),
            ),
          ),
          PasswordStrength(controller: _passwordController),
        ],
      ),
    );
  }

  Widget _title() {
    return Text(
      'JOIN\nEATINPAL',
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 44,
        height: 1.0,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    return Text(
      'Create an account to begin your journey toward healthier meals and more mindful habits.',
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }

  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        children: [
          AppButton(label: 'CREATE ACCOUNT', onPressed: _submit, height: 56),
          SIZED_BOX_H12,
          _loginLink(),
        ],
      ),
    );
  }

  Widget _loginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTypography.BODY_MEDIUM.copyWith(
            color: AppColors.NEUTRAL_40,
          ),
        ),
        GestureDetector(
          onTap: () => context.pushReplacement(RoutePaths.LOGIN),
          child: Text(
            'Log in',
            style: AppTypography.BODY_MEDIUM.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.NEUTRAL_10,
            ),
          ),
        ),
      ],
    );
  }
}

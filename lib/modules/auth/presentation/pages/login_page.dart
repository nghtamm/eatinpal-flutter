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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  // [KEY]
  final _formKey = GlobalKey<FormState>();

  // [CONTROLLER]
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // [STATE]
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
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
    if (state is AuthAuthenticated) {
      context.go(RoutePaths.HOME);
    } else if (state is AuthRequiresVerification) {
      context.pushReplacement(
        RoutePaths.VERIFY_EMAIL,
        extra: (
          email: _emailController.text.trim(),
          password: _passwordController.text,
          autoResend: true,
        ),
      );
    } else if (state is AuthFailure) {
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
            hint: 'Enter your email address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          SIZED_BOX_H20,
          AuthTextField(
            label: 'PASSWORD',
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: Validators.loginPassword,
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
          SIZED_BOX_H12,
          _forgotPassword(),
        ],
      ),
    );
  }

  Widget _title() {
    return Text(
      'WELCOME\nBACK',
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 44,
        height: 1.0,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    return Text(
      'Log in to EatinPal to continue.',
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }

  Widget _forgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => context.push(RoutePaths.FORGOT_PASSWORD),
        child: Text(
          'Forgot your password?',
          style: AppTypography.BODY_MEDIUM.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.NEUTRAL_10,
          ),
        ),
      ),
    );
  }

  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: AppButton(label: 'LOGIN', onPressed: _submit, height: 56),
    );
  }
}

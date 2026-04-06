import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/helpers/extensions.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_event.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_state.dart';
import 'package:eatinpal/modules/auth/presentation/widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RoutePaths.HOME);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.ERROR,
              ),
            );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.XL,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: AppColors.PRIMARY,
                    ),
                    SIZED_BOX_H8,
                    Text(
                      'EatinPal',
                      style: AppTypography.HEADING_2.copyWith(
                        color: AppColors.PRIMARY,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SIZED_BOX_H8,
                    Text(
                      'Sign in to your account',
                      style: AppTypography.BODY_2.copyWith(
                        color: AppColors.TEXT_SECONDARY,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SIZED_BOX_H40,
                    AuthTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.trim().isValidEmail) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SIZED_BOX_H16,
                    AuthTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SIZED_BOX_H32,
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.TEXT_ON_PRIMARY,
                                  ),
                                )
                              : const Text('Sign In'),
                        );
                      },
                    ),
                    SIZED_BOX_H16,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTypography.BODY_2.copyWith(
                            color: AppColors.TEXT_SECONDARY,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(RoutePaths.REGISTER),
                          child: Text(
                            'Sign Up',
                            style: AppTypography.BODY_2.copyWith(
                              color: AppColors.PRIMARY,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

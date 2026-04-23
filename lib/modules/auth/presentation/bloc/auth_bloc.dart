import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/domain/usecases/login_usecase.dart';
import 'package:eatinpal/modules/auth/domain/usecases/register_usecase.dart';
import 'package:eatinpal/modules/auth/domain/usecases/resend_verification_usecase.dart';
import 'package:eatinpal/modules/auth/domain/usecases/verified_login_usecase.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_event.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase _register;
  final LoginUseCase _login;
  final ResendVerificationUseCase _resendVerification;
  final VerifiedLoginUseCase _verifiedLogin;

  AuthBloc({
    required RegisterUseCase register,
    required LoginUseCase login,
    required ResendVerificationUseCase resendVerification,
    required VerifiedLoginUseCase verifiedLogin,
  }) : _register = register,
       _login = login,
       _resendVerification = resendVerification,
       _verifiedLogin = verifiedLogin,
       super(const AuthInitial()) {
    on<AuthRegisterSubmitted>(_onRegister);
    on<AuthLoginSubmitted>(_onLogin);
    on<AuthResendVerificationRequested>(_onResendVerification);
    on<AuthVerifiedLoginRequested>(_onVerifiedLogin);
  }

  Future<void> _onRegister(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _register(
      RegisterParams(
        email: event.email,
        password: event.password,
        name: event.name,
      ),
    );
    result.fold(
      (left) => emit(AuthFailure(left.message)),
      (right) => emit(AuthSuccess(right)),
    );
  }

  Future<void> _onLogin(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold((left) {
      if (left is ForbiddenException) {
        emit(AuthRequiresVerification(left.message));
      } else {
        emit(AuthFailure(left.message));
      }
    }, (right) => emit(AuthSuccess(right)));
  }

  Future<void> _onResendVerification(
    AuthResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInitial());
    final result = await _resendVerification(
      ResendVerificationParams(email: event.email),
    );
    result.fold(
      (left) => emit(AuthFailure(left.message)),
      (right) => emit(AuthSuccess(right)),
    );
  }

  Future<void> _onVerifiedLogin(
    AuthVerifiedLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _verifiedLogin();
    result.fold(
      (left) => emit(AuthFailure(left.message)),
      (right) => emit(AuthSuccess(right)),
    );
  }
}

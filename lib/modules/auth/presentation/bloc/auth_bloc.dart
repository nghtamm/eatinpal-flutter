import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/modules/auth/domain/usecases/login_usecase.dart';
import 'package:eatinpal/modules/auth/domain/usecases/register_usecase.dart';
import 'package:eatinpal/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_event.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;

  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
  })  : _login = login,
        _register = register,
        _logout = logout,
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (left) => emit(AuthError(left.message)),
      (right) => emit(AuthAuthenticated(right)),
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
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
      (left) => emit(AuthError(left.message)),
      (right) => emit(AuthAuthenticated(right)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _logout();
    result.fold(
      (left) => emit(AuthError(left.message)),
      (right) => emit(const AuthUnauthenticated()),
    );
  }
}

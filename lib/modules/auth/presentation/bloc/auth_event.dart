import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthRegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthRegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthResendVerificationRequested extends AuthEvent {
  final String email;

  const AuthResendVerificationRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthVerifiedLoginRequested extends AuthEvent {
  const AuthVerifiedLoginRequested();
}

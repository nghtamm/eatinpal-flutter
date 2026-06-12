import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordRequested extends ForgotPasswordEvent {
  final String email;

  const ForgotPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class OTPSubmitted extends ForgotPasswordEvent {
  final String email;
  final String otp;

  const OTPSubmitted({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class ResetSubmitted extends ForgotPasswordEvent {
  final String email;
  final String password;

  const ResetSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

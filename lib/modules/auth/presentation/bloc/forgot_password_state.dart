import 'package:equatable/equatable.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class OTPSent extends ForgotPasswordState {
  final String message;

  const OTPSent(this.message);

  @override
  List<Object?> get props => [message];
}

class OTPVerified extends ForgotPasswordState {
  final String message;

  const OTPVerified(this.message);

  @override
  List<Object?> get props => [message];
}

class ResetDone extends ForgotPasswordState {
  final String message;

  const ResetDone(this.message);

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String message;

  const ForgotPasswordFailure(this.message);

  @override
  List<Object?> get props => [message];
}

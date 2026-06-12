import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eatinpal/modules/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:eatinpal/modules/auth/domain/usecases/reset_password_usecase.dart';
import 'package:eatinpal/modules/auth/domain/usecases/verify_otp_usecase.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgotPasswordUseCase _forgotPassword;
  final VerifyOTPUseCase _verifyOTP;
  final ResetPasswordUseCase _resetPassword;

  ForgotPasswordBloc({
    required ForgotPasswordUseCase forgotPassword,
    required VerifyOTPUseCase verifyOTP,
    required ResetPasswordUseCase resetPassword,
  }) : _forgotPassword = forgotPassword,
       _verifyOTP = verifyOTP,
       _resetPassword = resetPassword,
       super(const ForgotPasswordInitial()) {
    on<ForgotPasswordRequested>(_onRequested);
    on<OTPSubmitted>(_onOTPSubmitted);
    on<ResetSubmitted>(_onResetSubmitted);
  }

  Future<void> _onRequested(
    ForgotPasswordRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    final result = await _forgotPassword(event.email);
    result.fold(
      (left) => emit(ForgotPasswordFailure(left.message)),
      (right) => emit(OTPSent(right)),
    );
  }

  Future<void> _onOTPSubmitted(
    OTPSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    final result = await _verifyOTP(
      VerifyOTPParams(email: event.email, otp: event.otp),
    );
    result.fold(
      (left) => emit(ForgotPasswordFailure(left.message)),
      (right) => emit(OTPVerified(right)),
    );
  }

  Future<void> _onResetSubmitted(
    ResetSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    final result = await _resetPassword(
      ResetPasswordParams(email: event.email, newPassword: event.password),
    );
    result.fold(
      (left) => emit(ForgotPasswordFailure(left.message)),
      (right) => emit(ResetDone(right)),
    );
  }
}

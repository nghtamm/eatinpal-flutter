import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

class VerifyOTPParams extends Equatable {
  final String email;
  final String otp;

  const VerifyOTPParams({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class VerifyOTPUseCase extends UseCase<String, VerifyOTPParams> {
  final AuthRepository _repository;

  VerifyOTPUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(VerifyOTPParams params) {
    return _repository.verifyOTP(email: params.email, otp: params.otp);
  }
}

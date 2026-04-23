import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class ResendVerificationParams {
  final String email;

  const ResendVerificationParams({required this.email});
}

class ResendVerificationUseCase
    extends UseCase<String, ResendVerificationParams> {
  final AuthRepository _repository;

  ResendVerificationUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(ResendVerificationParams params) {
    return _repository.resendVerification(email: params.email);
  }
}

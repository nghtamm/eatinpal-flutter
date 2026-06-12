import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

class ForgotPasswordUseCase extends UseCase<String, String> {
  final AuthRepository _repository;

  ForgotPasswordUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(String email) {
    return _repository.forgotPassword(email: email);
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class ResendUseCase extends UseCase<String, String> {
  final AuthRepository _repository;

  ResendUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(String email) {
    return _repository.resend(email: email);
  }
}

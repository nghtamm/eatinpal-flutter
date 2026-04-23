import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class VerifiedLoginUseCase extends UseCaseNoParams<String> {
  final AuthRepository _repository;

  VerifiedLoginUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call() {
    return _repository.verifiedLogin();
  }
}

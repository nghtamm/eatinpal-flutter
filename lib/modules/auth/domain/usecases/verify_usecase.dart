import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class VerifyUseCase extends UseCase<String, String> {
  final AuthRepository _repository;

  VerifyUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(String token) {
    return _repository.verify(token: token);
  }
}

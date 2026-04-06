import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/use_case/use_case.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class LogoutUseCase extends UseCaseNoParams<void> {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  @override
  Future<Either<AppException, void>> call() {
    return _repository.logout();
  }
}

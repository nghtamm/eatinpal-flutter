import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import 'package:eatinpal/modules/auth/domain/entities/user_entity.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class GetProfileUseCase extends UseCaseNoParams<UserEntity> {
  final AuthRepository _repository;

  GetProfileUseCase(this._repository);

  @override
  Future<Either<AppException, UserEntity>> call() {
    return _repository.getProfile();
  }
}

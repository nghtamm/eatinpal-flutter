import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/use_case/use_case.dart';
import 'package:eatinpal/modules/auth/domain/entities/user_entity.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class RegisterParams {
  final String email;
  final String password;
  final String name;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
  });
}

class RegisterUseCase extends UseCase<UserEntity, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<AppException, UserEntity>> call(RegisterParams params) {
    return _repository.register(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

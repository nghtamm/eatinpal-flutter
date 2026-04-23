import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
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

class RegisterUseCase extends UseCase<String, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(RegisterParams params) {
    return _repository.register(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

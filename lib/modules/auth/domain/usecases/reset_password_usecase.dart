import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

class ResetPasswordParams extends Equatable {
  final String email;
  final String newPassword;

  const ResetPasswordParams({required this.email, required this.newPassword});

  @override
  List<Object?> get props => [email, newPassword];
}

class ResetPasswordUseCase extends UseCase<String, ResetPasswordParams> {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(ResetPasswordParams params) {
    return _repository.resetPassword(
      email: params.email,
      newPassword: params.newPassword,
    );
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<AppException, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<AppException, UserEntity>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<AppException, void>> logout();

  Future<Either<AppException, UserEntity>> getProfile();
}

import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';

abstract class AuthRepository {
  Future<Either<AppException, String>> login({
    required String email,
    required String password,
  });

  Future<Either<AppException, String>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<AppException, String>> resendVerification({
    required String email,
  });

  Future<Either<AppException, String>> verifiedLogin();
}

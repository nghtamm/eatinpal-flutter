import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/data/services/auth_service.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _service;
  final LocalStorage _storage;

  const AuthRepositoryImpl(this._service, this._storage);

  @override
  Future<Either<AppException, String>> login({
    required String email,
    required String password,
  }) async {
    final result = await _service.login(email: email, password: password);

    return result.fold((left) async => Left(left), (right) async {
      await _storage.saveCredentialsToken(
        accessToken: right.data.credentials.accessToken,
        refreshToken: right.data.credentials.refreshToken,
      );

      return Right(right.message);
    });
  }

  @override
  Future<Either<AppException, String>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _service.register(
      email: email,
      password: password,
      name: name,
    );

    return result.fold((left) => Left(left), (right) => Right(right.message));
  }

  @override
  Future<Either<AppException, String>> resend({required String email}) async {
    final result = await _service.resend(email: email);

    return result.fold((left) => Left(left), (right) => Right(right.message));
  }

  @override
  Future<Either<AppException, String>> verify({required String token}) async {
    final result = await _service.verify(verificationToken: token);

    return result.fold((left) => Left(left), (right) => Right(right.message));
  }

  @override
  Future<Either<AppException, String>> magicLink({
    required String token,
  }) async {
    final result = await _service.magicLink(verificationToken: token);

    return result.fold((left) async => Left(left), (right) async {
      await _storage.saveCredentialsToken(
        accessToken: right.data.credentials.accessToken,
        refreshToken: right.data.credentials.refreshToken,
      );

      return Right(right.message);
    });
  }
}

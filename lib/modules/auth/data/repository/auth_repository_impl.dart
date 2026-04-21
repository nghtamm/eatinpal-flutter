import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/data/services/auth_service.dart';
import 'package:eatinpal/modules/auth/domain/entities/user_entity.dart';
import 'package:eatinpal/modules/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _service;
  final LocalStorage _storage;

  const AuthRepositoryImpl(this._service, this._storage);

  @override
  Future<Either<AppException, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    final result = await _service.login(email: email, password: password);
    return result.fold(
      (left) async => Left(left),
      (right) async {
        await _storage.saveCredentialsToken(
          accessToken: right.accessToken,
          refreshToken: right.refreshToken,
        );
        return Right(right.user);
      },
    );
  }

  @override
  Future<Either<AppException, UserEntity>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _service.register(
      email: email,
      password: password,
      name: name,
    );
    return result.fold(
      (left) async => Left(left),
      (right) async {
        await _storage.saveCredentialsToken(
          accessToken: right.accessToken,
          refreshToken: right.refreshToken,
        );
        return Right(right.user);
      },
    );
  }

  @override
  Future<Either<AppException, void>> logout() async {
    final result = await _service.logout();
    return result.fold(
      (left) async => Left(left),
      (right) async {
        await _storage.clearCredentialsToken();
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<AppException, UserEntity>> getProfile() {
    return _service.getProfile();
  }
}

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
    switch (result) {
      case Left(value: final error):
        return Left(error);
      case Right(value: final token):
        await _storage.saveTokens(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
        );
        return Right(token.user);
    }
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
    switch (result) {
      case Left(value: final error):
        return Left(error);
      case Right(value: final token):
        await _storage.saveTokens(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
        );
        return Right(token.user);
    }
  }

  @override
  Future<Either<AppException, void>> logout() async {
    final result = await _service.logout();
    switch (result) {
      case Left(value: final error):
        return Left(error);
      case Right():
        await _storage.clearTokens();
        return const Right(null);
    }
  }

  @override
  Future<Either<AppException, UserEntity>> getProfile() {
    return _service.getProfile();
  }
}

import 'dart:convert';

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
        accessToken: right.data.tokens.accessToken,
        refreshToken: right.data.tokens.refreshToken,
      );

      final userJSON = jsonEncode(right.data.user.toJson());
      await _storage.saveUser(userJSON);

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
    
    return result.fold((left) async => Left(left), (right) async {
      await _storage.saveVerificationToken(right.data);
      return Right(right.message);
    });
  }

  @override
  Future<Either<AppException, String>> resendVerification({
    required String email,
  }) async {
    final result = await _service.resendVerification(email: email);

    return result.fold((left) async => Left(left), (right) async {
      await _storage.saveVerificationToken(right.data);
      return Right(right.message);
    });
  }

  @override
  Future<Either<AppException, String>> verifiedLogin() async {
    final token = await _storage.verificationToken;
    final result = await _service.verifiedLogin(verificationToken: token ?? '');

    return result.fold((left) async => Left(left), (right) async {
      await _storage.saveCredentialsToken(
        accessToken: right.data.tokens.accessToken,
        refreshToken: right.data.tokens.refreshToken,
      );

      final userJSON = jsonEncode(right.data.user.toJson());
      await _storage.saveUser(userJSON);

      await _storage.clearVerificationToken();

      return Right(right.message);
    });
  }
}

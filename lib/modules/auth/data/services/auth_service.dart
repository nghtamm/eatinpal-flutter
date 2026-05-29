import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';
import 'package:eatinpal/core/network/api_methods.dart';
import 'package:eatinpal/core/network/api_result.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/data/models/credentials_model.dart';
import 'package:eatinpal/modules/auth/data/models/user_model.dart';

typedef LoginResponse = ({UserModel user, CredentialsModel credentials});

class AuthService {
  final ApiClient _client;

  const AuthService(this._client);

  Future<Either<AppException, ApiResult<LoginResponse>>> login({
    required String email,
    required String password,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.LOGIN,
      method: RestMethod.POST,
      data: {'email': email, 'password': password},
      parser: (data) {
        return (
          user: UserModel.fromJson(data['user']),
          credentials: CredentialsModel.fromJson(data['tokens']),
        );
      },
    );
  }

  Future<Either<AppException, ApiResult<void>>> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.REGISTER,
      method: RestMethod.POST,
      data: {'email': email, 'password': password, 'name': name},
      parser: (_) {},
    );
  }

  Future<Either<AppException, ApiResult<void>>> resend({
    required String email,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.RESEND,
      method: RestMethod.POST,
      data: {'email': email},
      parser: (_) {},
    );
  }

  Future<Either<AppException, ApiResult<void>>> verify({
    required String verificationToken,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.VERIFY,
      method: RestMethod.GET,
      query: {'token': verificationToken},
      headers: {Headers.acceptHeader: Headers.jsonContentType},
      parser: (_) {},
    );
  }

  Future<Either<AppException, ApiResult<LoginResponse>>> magicLink({
    required String verificationToken,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.MAGIC_LINK,
      method: RestMethod.POST,
      data: {'verification_token': verificationToken},
      parser: (data) {
        return (
          user: UserModel.fromJson(data['user']),
          credentials: CredentialsModel.fromJson(data['tokens']),
        );
      },
    );
  }
}

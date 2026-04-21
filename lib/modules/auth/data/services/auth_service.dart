import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';
import 'package:eatinpal/core/network/api_methods.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/data/models/auth_token_model.dart';
import 'package:eatinpal/modules/auth/data/models/user_model.dart';

class AuthService {
  final ApiClient _client;

  const AuthService(this._client);

  Future<Either<AppException, AuthTokenModel>> login({
    required String email,
    required String password,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.LOGIN,
      method: RestMethod.POST,
      data: {'email': email, 'password': password},
      parser: (data) => AuthTokenModel.fromJson(data),
    );
  }

  Future<Either<AppException, AuthTokenModel>> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.REGISTER,
      method: RestMethod.POST,
      data: {'email': email, 'password': password, 'name': name},
      parser: (data) => AuthTokenModel.fromJson(data),
    );
  }

  Future<Either<AppException, void>> logout() {
    return _client.request(
      endpoint: ApiEndpoints.LOGOUT,
      method: RestMethod.POST,
      parser: (_) {},
    );
  }

  Future<Either<AppException, UserModel>> getProfile() {
    return _client.request(
      endpoint: ApiEndpoints.PROFILE,
      method: RestMethod.GET,
      parser: (data) => UserModel.fromJson(data),
    );
  }
}

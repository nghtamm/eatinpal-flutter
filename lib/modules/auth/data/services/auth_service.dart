import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';
import 'package:eatinpal/core/network/api_methods.dart';
import 'package:eatinpal/core/network/api_result.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/data/models/tokens_model.dart';
import 'package:eatinpal/modules/auth/data/models/user_model.dart';

typedef LoginResponse = ({UserModel user, TokensModel tokens});

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
        final map = data as Map<String, dynamic>;
        return (
          user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
          tokens: TokensModel.fromJson(map['tokens'] as Map<String, dynamic>),
        );
      },
    );
  }

  Future<Either<AppException, ApiResult<String>>> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.REGISTER,
      method: RestMethod.POST,
      data: {'email': email, 'password': password, 'name': name},
      parser: (data) =>
          (data as Map<String, dynamic>)['verification_token'] as String,
    );
  }

  Future<Either<AppException, ApiResult<String>>> resendVerification({
    required String email,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.RESEND_VERIFICATION,
      method: RestMethod.POST,
      data: {'email': email},
      parser: (data) =>
          (data as Map<String, dynamic>)['verification_token'] as String,
    );
  }

  Future<Either<AppException, ApiResult<LoginResponse>>> verifiedLogin({
    required String verificationToken,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.VERIFIED_LOGIN,
      method: RestMethod.POST,
      data: {'verification_token': verificationToken},
      parser: (data) {
        final map = data as Map<String, dynamic>;
        return (
          user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
          tokens: TokensModel.fromJson(map['tokens'] as Map<String, dynamic>),
        );
      },
    );
  }
}

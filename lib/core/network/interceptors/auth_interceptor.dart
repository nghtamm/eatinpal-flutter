import 'package:dio/dio.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;
  final LocalStorage _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refresh = await _storage.refreshToken;
    if (refresh == null) {
      await _storage.clearCredentialsToken();
      return handler.next(err);
    }

    try {
      final response = await _dioConfig().post(
        ApiEndpoints.REFRESH,
        data: {'refresh_token': refresh},
      );

      final rotatedAT = response.data['access_token'] as String;
      final rotatedRT = response.data['refresh_token'] as String;

      await _storage.saveCredentialsToken(
        accessToken: rotatedAT,
        refreshToken: rotatedRT,
      );

      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $rotatedAT';

      final retry = await _dio.fetch(opts);
      return handler.resolve(retry);
    } on DioException {
      await _storage.clearCredentialsToken();
      return handler.next(err);
    }
  }

  Dio _dioConfig() {
    return Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.BASE_URL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }
}

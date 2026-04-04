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
      await _storage.clearTokens();
      return handler.next(err);
    }

    try {
      final response = await _tokenRefreshDio().post(
        ApiEndpoints.REFRESH,
        data: {'refreshToken': refresh},
      );

      final newAccess = response.data['accessToken'] as String;
      final newRefresh = response.data['refreshToken'] as String?;

      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh ?? refresh,
      );

      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';

      final retryResponse = await _dio.fetch(opts);
      return handler.resolve(retryResponse);
    } on DioException {
      await _storage.clearTokens();
      return handler.next(err);
    }
  }

  Dio _tokenRefreshDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.API_V1,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }
}

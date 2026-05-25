import 'package:dio/dio.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;
  final LocalStorage _storage;
  Future<bool>? _refreshing;

  AuthInterceptor(this._storage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.BASE_URL,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.accessToken;
    if (token != null && token.isNotEmpty) {
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
    if (refresh == null || refresh.isEmpty) {
      await _storage.clearCredentialsToken();
      return handler.next(err);
    }

    final ok = await (_refreshing ??= _refresh(
      refresh,
    )).whenComplete(() => _refreshing = null);
    if (!ok) return handler.next(err);

    final opts = err.requestOptions;
    opts.headers['Authorization'] = 'Bearer ${await _storage.accessToken}';
    try {
      final retry = await _dio.fetch(opts);
      handler.resolve(retry);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  Future<bool> _refresh(String token) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.REFRESH,
        data: {'refresh_token': token},
      );

      final rotatedAT = response.data['access_token'];
      final rotatedRT = response.data['refresh_token'];
      if (rotatedAT == null ||
          rotatedRT == null ||
          rotatedAT.isEmpty ||
          rotatedRT.isEmpty) {
        await _storage.clearCredentialsToken();
        return false;
      }

      await _storage.saveCredentialsToken(
        accessToken: rotatedAT,
        refreshToken: rotatedRT,
      );
      return true;
    } on DioException catch (err) {
      final code = err.response?.statusCode;
      if (code == 401 || code == 403) {
        await _storage.clearCredentialsToken();
      }
      return false;
    }
  }
}

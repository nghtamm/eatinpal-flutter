import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';
import 'package:eatinpal/core/network/api_methods.dart';
import 'package:eatinpal/core/network/api_result.dart';
import 'package:eatinpal/core/network/error_handler.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/network/interceptors/auth_interceptor.dart';
import 'package:eatinpal/core/network/interceptors/logging_interceptor.dart';
import 'package:eatinpal/core/local/local_storage.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio, LocalStorage storage) {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.BASE_URL,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_dio, storage),
      LoggingInterceptor(),
    ]);
  }

  Future<Either<AppException, ApiResult<T>>> request<T>({
    required String endpoint,
    required RestMethod method,
    Map<String, dynamic>? query,
    dynamic data,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? parser,
  }) async {
    try {
      final options = Options(headers: headers);

      final response = switch (method) {
        RestMethod.GET => await _dio.get(
          endpoint,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken,
        ),
        RestMethod.POST => await _dio.post(
          endpoint,
          data: data,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken,
        ),
        RestMethod.PUT => await _dio.put(
          endpoint,
          data: data,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken,
        ),
        RestMethod.PATCH => await _dio.patch(
          endpoint,
          data: data,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken,
        ),
        RestMethod.DELETE => await _dio.delete(
          endpoint,
          data: data,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken,
        ),
      };

      return Right(_unwrap(response, parser));
    } on DioException catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  Future<Either<AppException, ApiResult<T>>> upload<T>({
    required String endpoint,
    required FormData formData,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onProgress,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            ...?headers,
            Headers.contentTypeHeader: Headers.multipartFormDataContentType,
          },
        ),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );

      return Right(_unwrap(response, parser));
    } on DioException catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  ApiResult<T> _unwrap<T>(Response response, T Function(dynamic)? parser) {
    final envelope = response.data as Map<String, dynamic>;
    final status =
        envelope['status_code'] as int? ?? response.statusCode ?? 200;
    final message = envelope['message'] as String? ?? '';
    final data = parser != null
        ? parser(envelope['data'])
        : envelope['data'] as T;
    return ApiResult(statusCode: status, message: message, data: data);
  }
}

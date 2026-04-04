import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      log(
        '[REQ] ${options.method} ${options.uri}\n'
        'Headers: ${options.headers}\n'
        'Data: ${options.data}',
        name: 'API',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      log(
        '[RES] ${response.statusCode} ${response.requestOptions.uri}\n'
        'Data: ${response.data}',
        name: 'API',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      log(
        '[ERR] ${err.response?.statusCode} ${err.requestOptions.uri}\n'
        'Message: ${err.message}\n'
        'Data: ${err.response?.data}',
        name: 'API',
      );
    }
    handler.next(err);
  }
}

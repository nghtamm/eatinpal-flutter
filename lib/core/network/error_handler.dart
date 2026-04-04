import 'package:dio/dio.dart';
import 'package:eatinpal/core/network/exceptions.dart';

abstract final class ErrorHandler {
  static AppException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.cancel:
        return const CancelException();

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Invalid certificate',
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: error.message ?? 'Unknown error',
        );
    }
  }

  static AppException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final message = _extractMessage(data);

    switch (statusCode) {
      case 400:
        return NetworkException(
          message: message ?? 'Bad request',
          statusCode: 400,
          data: data,
        );
      case 401:
        return UnauthorizedException(data: data);
      case 403:
        return ForbiddenException(data: data);
      case 404:
        return NotFoundException(data: data);
      case 422:
        return ValidationException(
          message: message ?? 'Validation failed',
          data: data,
          errors: data is Map<String, dynamic>
              ? data['errors'] as Map<String, dynamic>?
              : null,
        );
      case 500:
        return ServerException(data: data);
      default:
        return NetworkException(
          message: message ?? 'Server error',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}

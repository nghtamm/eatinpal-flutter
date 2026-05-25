import 'package:dio/dio.dart';
import 'package:eatinpal/core/network/exceptions.dart';

abstract final class ErrorHandler {
  static const _MSG_INVALID_REQUEST =
      "We couldn't process this request. Please try again.";
  static const _MSG_SESSION_EXPIRED =
      'Your session has expired. Please log in again.';
  static const _MSG_SERVICE_UNAVAILABLE =
      'Service is temporarily unavailable. Please try again shortly.';
  static const _MSG_TIMEOUT =
      'The request took too long. Please check your connection and try again.';
  static const _MSG_CANCEL = 'The request was cancelled.';
  static const _MSG_NO_INTERNET =
      'No internet connection. Please check your network.';
  static const _MSG_UNEXPECTED = 'Something went wrong. Please try again.';

  static AppException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(message: _MSG_TIMEOUT);

      case DioExceptionType.cancel:
        return const CancelException(message: _MSG_CANCEL);

      case DioExceptionType.connectionError:
        return const NoInternetException(message: _MSG_NO_INTERNET);

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.badCertificate:
        return const NetworkException(message: _MSG_UNEXPECTED);

      case DioExceptionType.unknown:
        return const NetworkException(message: _MSG_UNEXPECTED);
    }
  }

  static AppException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final message = _extractMessage(data);

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: message ?? _MSG_INVALID_REQUEST,
          data: data,
        );
      case 401:
        return UnauthorizedException(
          message: message ?? _MSG_SESSION_EXPIRED,
          data: data,
        );
      case 403:
        return ForbiddenException(
          message: message ?? _MSG_SESSION_EXPIRED,
          data: data,
        );
      case 404:
        return NotFoundException(
          message: message ?? _MSG_INVALID_REQUEST,
          data: data,
        );
      case 406:
        return NotAcceptableException(
          message: message ?? _MSG_INVALID_REQUEST,
          data: data,
        );
      case 408:
        return RequestTimeoutException(
          message: message ?? _MSG_SERVICE_UNAVAILABLE,
          data: data,
        );
      case 409:
        return ConflictException(
          message: message ?? _MSG_INVALID_REQUEST,
          data: data,
        );
      case 413:
        return PayloadTooLargeException(
          message: message ?? _MSG_INVALID_REQUEST,
          data: data,
        );
      case 500:
        return InternalServerErrorException(
          message: message ?? _MSG_SERVICE_UNAVAILABLE,
          data: data,
        );
      case 502:
        return BadGatewayException(
          message: message ?? _MSG_SERVICE_UNAVAILABLE,
          data: data,
        );
      case 503:
        return ServiceUnavailableException(
          message: message ?? _MSG_SERVICE_UNAVAILABLE,
          data: data,
        );
      case 504:
        return GatewayTimeoutException(
          message: message ?? _MSG_SERVICE_UNAVAILABLE,
          data: data,
        );
      default:
        return NetworkException(
          message: message ?? _MSG_UNEXPECTED,
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

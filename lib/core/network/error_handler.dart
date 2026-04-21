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
        return const NetworkException(message: 'Invalid certificate');

      case DioExceptionType.unknown:
        return NetworkException(message: error.message ?? 'Unknown error');
    }
  }

  static AppException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final message = _extractMessage(data);

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: message ?? 'Bad request',
          data: data,
        );
      case 401:
        return UnauthorizedException(
          message: message ?? 'Unauthorized',
          data: data,
        );
      case 403:
        return ForbiddenException(message: message ?? 'Forbidden', data: data);
      case 404:
        return NotFoundException(message: message ?? 'Not found', data: data);
      case 406:
        return NotAcceptableException(
          message: message ?? 'Not acceptable',
          data: data,
        );
      case 408:
        return RequestTimeoutException(
          message: message ?? 'Request timeout',
          data: data,
        );
      case 409:
        return ConflictException(message: message ?? 'Conflict', data: data);
      case 413:
        return PayloadTooLargeException(
          message: message ?? 'Payload too large',
          data: data,
        );
      case 500:
        return InternalServerErrorException(
          message: message ?? 'Internal server error',
          data: data,
        );
      case 502:
        return BadGatewayException(
          message: message ?? 'Bad gateway',
          data: data,
        );
      case 503:
        return ServiceUnavailableException(
          message: message ?? 'Service unavailable',
          data: data,
        );
      case 504:
        return GatewayTimeoutException(
          message: message ?? 'Gateway timeout',
          data: data,
        );
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

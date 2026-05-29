import 'package:dio/dio.dart';
import 'package:eatinpal/core/network/exceptions.dart';

abstract final class ErrorHandler {
  static AppException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(
          message: 'Connection timed out. Please try again.',
        );

      case DioExceptionType.cancel:
        return const CancelException(
          message: 'The request was cancelled. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const NoInternetException(
          message:
              'No internet connection. Please check your connection and try again.',
        );

      case DioExceptionType.badResponse:
        return _handleErrResponse(error.response);

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'An error occurred unexpectedly. Please try again later.',
        );

      case DioExceptionType.unknown:
        return const NetworkException(
          message: 'An error occurred unexpectedly. Please try again later.',
        );
    }
  }

  static AppException _handleErrResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final message = _extractMessage(data);

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
          data: data,
        );
      case 401:
        return UnauthorizedException(
          message: message ?? 'Your session has expired. Please log in again.',
          data: data,
        );
      case 403:
        return ForbiddenException(
          message:
              message ??
              '''You don't have permission to perform this action.''',
          data: data,
        );
      case 404:
        return NotFoundException(
          message: message ?? 'The requested resource was not found.',
          data: data,
        );
      case 406:
        return NotAcceptableException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
          data: data,
        );
      case 408:
        return RequestTimeoutException(
          message: message ?? 'Connection timed out. Please try again.',
          data: data,
        );
      case 409:
        return ConflictException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
          data: data,
        );
      case 413:
        return PayloadTooLargeException(
          message:
              message ??
              'File size limit exceeded. Please choose a smaller file and try again.',
          data: data,
        );
      case 500:
        return InternalServerErrorException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
          data: data,
        );
      case 502:
        return BadGatewayException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
          data: data,
        );
      case 503:
        return ServiceUnavailableException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
          data: data,
        );
      case 504:
        return GatewayTimeoutException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
          data: data,
        );
      default:
        return NetworkException(
          message:
              message ??
              'An error occurred unexpectedly. Please try again later.',
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

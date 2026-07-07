class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.data,
  });

  @override
  String toString() => 'AppException($statusCode): $message';
}

class BadRequestException extends AppException {
  const BadRequestException({
    super.message = 'Bad request',
    super.statusCode = 400,
    super.errorCode,
    super.data,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.statusCode = 401,
    super.errorCode,
    super.data,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Forbidden',
    super.statusCode = 403,
    super.errorCode,
    super.data,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Not found',
    super.statusCode = 404,
    super.errorCode,
    super.data,
  });
}

class NotAcceptableException extends AppException {
  const NotAcceptableException({
    super.message = 'Not acceptable',
    super.statusCode = 406,
    super.errorCode,
    super.data,
  });
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException({
    super.message = 'Request timeout',
    super.statusCode = 408,
    super.errorCode,
    super.data,
  });
}

class ConflictException extends AppException {
  const ConflictException({
    super.message = 'Conflict',
    super.statusCode = 409,
    super.errorCode,
    super.data,
  });
}

class PayloadTooLargeException extends AppException {
  const PayloadTooLargeException({
    super.message = 'Payload too large',
    super.statusCode = 413,
    super.errorCode,
    super.data,
  });
}

class InternalServerErrorException extends AppException {
  const InternalServerErrorException({
    super.message = 'Internal server error',
    super.statusCode = 500,
    super.errorCode,
    super.data,
  });
}

class BadGatewayException extends AppException {
  const BadGatewayException({
    super.message = 'Bad gateway',
    super.statusCode = 502,
    super.errorCode,
    super.data,
  });
}

class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException({
    super.message = 'Service unavailable',
    super.statusCode = 503,
    super.errorCode,
    super.data,
  });
}

class GatewayTimeoutException extends AppException {
  const GatewayTimeoutException({
    super.message = 'Gateway timeout',
    super.statusCode = 504,
    super.errorCode,
    super.data,
  });
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.data,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.statusCode,
    super.errorCode,
    super.data,
  });
}

class CancelException extends AppException {
  const CancelException({
    super.message = 'Request cancelled',
    super.statusCode,
    super.errorCode,
    super.data,
  });
}

class NoInternetException extends AppException {
  const NoInternetException({
    super.message = 'No internet connection',
    super.statusCode,
    super.errorCode,
    super.data,
  });
}

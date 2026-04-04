class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'AppException($statusCode): $message';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode, super.data});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.statusCode = 401,
    super.data,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Forbidden',
    super.statusCode = 403,
    super.data,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Not found',
    super.statusCode = 404,
    super.data,
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Internal server error',
    super.statusCode = 500,
    super.data,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.statusCode,
    super.data,
  });
}

class CancelException extends AppException {
  const CancelException({
    super.message = 'Request cancelled',
    super.statusCode,
    super.data,
  });
}

class NoInternetException extends AppException {
  const NoInternetException({
    super.message = 'No internet connection',
    super.statusCode,
    super.data,
  });
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  const ValidationException({
    super.message = 'Validation failed',
    super.statusCode = 422,
    super.data,
    this.errors,
  });
}

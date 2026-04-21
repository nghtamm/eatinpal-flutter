import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiEndpoints {
  static String get BASE_URL =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:3000';

  // Auth
  static const String LOGIN = '/auth/login';
  static const String REGISTER = '/auth/register';
  static const String REFRESH = '/auth/refresh';
  static const String LOGOUT = '/auth/logout';
  static const String PROFILE = '/auth/profile';
}

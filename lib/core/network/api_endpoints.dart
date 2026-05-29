import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiEndpoints {
  static String get BASE_URL =>
      dotenv.env['BASE_URL'] ?? 'https://eatinpal.nport.link';

  // [AUTH]
  static const String LOGIN = '/auth/login';
  static const String REGISTER = '/auth/register';
  static const String REFRESH = '/auth/refresh';
  static const String RESEND = '/auth/resend';
  static const String VERIFY = '/auth/verify';
  static const String MAGIC_LINK = '/auth/magic-link';
}

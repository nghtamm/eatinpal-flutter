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
  static const String FORGOT_PASSWORD = '/auth/forgot-password';
  static const String VERIFY_OTP = '/auth/verify-otp';
  static const String RESET_PASSWORD = '/auth/reset-password';
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiEndpoints {
  static String get BASE_URL => dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
  static String get API_V1 => '$BASE_URL/api/v1';

  // Auth
  static const String LOGIN = '/auth/login';
  static const String REGISTER = '/auth/register';
  static const String REFRESH = '/auth/refresh';
  static const String LOGOUT = '/auth/logout';
  static const String PROFILE = '/auth/profile';

  // Tracking
  static const String DAILY_LOG = '/tracking/daily';
  static const String MEALS = '/tracking/meals';

  // Food
  static const String FOOD_SEARCH = '/food/search';
  static const String FOOD_DETAIL = '/food';

  // Schedule
  static const String SCHEDULE_WEEKLY = '/schedule/weekly';
  static const String SCHEDULE_MONTHLY = '/schedule/monthly';
}

import 'package:app_links/app_links.dart';
import 'package:eatinpal/app/app.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/helpers/jwt.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.TRANSPARENT,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  await dotenv.load();
  await initDependencies();
  final route = await _routeBootstrap();
  runApp(App(initDest: route));
}

Future<String> _routeBootstrap() async {
  final link = await sl<AppLinks>().getInitialLink();
  if (link == null || !link.path.endsWith('/auth/verify')) {
    return RoutePaths.AUTHENTICATION;
  }

  final token = link.queryParameters['token'];
  if (token == null || token.isEmpty) return RoutePaths.AUTHENTICATION;

  final storage = sl<LocalStorage>();
  if (await storage.signed) return RoutePaths.HOME;
  if (isJWTExpired(token)) return RoutePaths.AUTHENTICATION;

  await storage.saveVerificationToken(token);
  return RoutePaths.VERIFICATION_SUCCESS;
}

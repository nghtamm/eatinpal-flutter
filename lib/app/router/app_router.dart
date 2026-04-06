import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/pages/home_page.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/modules/auth/auth.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.SPLASH,
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: RoutePaths.SPLASH,
        name: RouteNames.SPLASH,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.LOGIN,
        name: RouteNames.LOGIN,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.REGISTER,
        name: RouteNames.REGISTER,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.HOME,
        name: RouteNames.HOME,
        builder: (_, _) => const HomePage(),
      ),
    ],
  );
}

Future<String?> _guard(
  BuildContext context,
  GoRouterState state,
) async {
  final storage = sl<LocalStorage>();
  final loggedIn = await storage.isLoggedIn;
  final isSplash = state.matchedLocation == RoutePaths.SPLASH;
  final isAuth = state.matchedLocation == RoutePaths.LOGIN ||
      state.matchedLocation == RoutePaths.REGISTER;

  if (isSplash) {
    return loggedIn ? RoutePaths.HOME : RoutePaths.LOGIN;
  }

  if (!loggedIn && !isAuth) {
    return RoutePaths.LOGIN;
  }

  if (loggedIn && isAuth) {
    return RoutePaths.HOME;
  }

  return null;
}

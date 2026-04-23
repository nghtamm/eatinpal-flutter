import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/modules/auth/auth.dart';

final navigatorKey = GlobalKey<NavigatorState>();

GoRouter router() {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RoutePaths.WELCOME,
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: RoutePaths.WELCOME,
        name: RouteNames.WELCOME,
        builder: (_, _) => const AuthenticationPage(),
      ),
      GoRoute(
        path: RoutePaths.REGISTER,
        name: RouteNames.REGISTER,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.LOGIN,
        name: RouteNames.LOGIN,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.VERIFY_EMAIL,
        name: RouteNames.VERIFY_EMAIL,
        builder: (_, state) =>
            VerifyEmailPage(email: state.extra as String?),
      ),
      GoRoute(
        path: RoutePaths.VERIFICATION_SUCCESS,
        name: RouteNames.VERIFICATION_SUCCESS,
        builder: (_, state) =>
            VerificationSuccessPage(token: state.extra as String?),
      ),
    ],
  );
}

Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final storage = sl<LocalStorage>();
  final signed = await storage.signed;

  final location = state.matchedLocation;
  final destSplash = location == RoutePaths.WELCOME;
  final destAuth =
      location == RoutePaths.WELCOME ||
      location == RoutePaths.REGISTER ||
      location == RoutePaths.LOGIN ||
      location == RoutePaths.VERIFY_EMAIL ||
      location == RoutePaths.VERIFICATION_SUCCESS;

  if (destSplash) return signed ? RoutePaths.WELCOME : RoutePaths.WELCOME;
  if (!signed && !destAuth) return RoutePaths.WELCOME;
  // TODO: khi có home, uncomment để chặn user đã login vào lại auth routes
  // if (signed && destAuth) return RoutePaths.HOME;

  return null;
}

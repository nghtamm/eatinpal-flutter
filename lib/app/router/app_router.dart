import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/modules/auth/auth.dart';

final navigatorKey = GlobalKey<NavigatorState>();
const _DEST_AUTH = {
  RoutePaths.AUTHENTICATION,
  RoutePaths.REGISTER,
  RoutePaths.LOGIN,
  RoutePaths.VERIFY_EMAIL,
  RoutePaths.VERIFICATION_SUCCESS,
  RoutePaths.FORGOT_PASSWORD,
  RoutePaths.VERIFY_OTP,
  RoutePaths.RESET_PASSWORD,
};

GoRouter router() {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RoutePaths.AUTHENTICATION,
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: RoutePaths.AUTHENTICATION,
        name: RouteNames.AUTHENTICATION,
        builder: (_, _) {
          return const AuthenticationPage();
        },
      ),
      GoRoute(
        path: RoutePaths.REGISTER,
        name: RouteNames.REGISTER,
        builder: (_, _) {
          return const RegisterPage();
        },
      ),
      GoRoute(
        path: RoutePaths.LOGIN,
        name: RouteNames.LOGIN,
        builder: (_, _) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: RoutePaths.VERIFY_EMAIL,
        name: RouteNames.VERIFY_EMAIL,
        builder: (_, state) {
          return VerifyEmailPage(args: state.extra as VerifyEmailArgs?);
        },
      ),
      GoRoute(
        path: RoutePaths.VERIFICATION_SUCCESS,
        name: RouteNames.VERIFICATION_SUCCESS,
        builder: (_, state) {
          return VerificationSuccessPage(token: state.extra as String?);
        },
      ),
      GoRoute(
        path: RoutePaths.FORGOT_PASSWORD,
        name: RouteNames.FORGOT_PASSWORD,
        builder: (_, _) {
          return const ForgotPasswordPage();
        },
      ),
      GoRoute(
        path: RoutePaths.VERIFY_OTP,
        name: RouteNames.VERIFY_OTP,
        builder: (_, state) {
          return EnterCodePage(email: state.extra as String?);
        },
      ),
      GoRoute(
        path: RoutePaths.RESET_PASSWORD,
        name: RouteNames.RESET_PASSWORD,
        builder: (_, state) {
          return NewPasswordPage(email: state.extra as String?);
        },
      ),
      GoRoute(
        path: RoutePaths.HOME,
        name: RouteNames.HOME,
        builder: (_, _) {
          return const HomePage();
        },
      ),
    ],
  );
}

Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final signed = await di<LocalStorage>().signed;
  final destAuth = _DEST_AUTH.contains(state.matchedLocation);

  if (signed && destAuth) {
    return RoutePaths.HOME;
  } else if (!signed && !destAuth) {
    return RoutePaths.AUTHENTICATION;
  } else {
    return null;
  }
}

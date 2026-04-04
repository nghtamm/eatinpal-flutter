import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/di/service_locator.dart';

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
        builder: (_, __) => const _SplashPlaceholder(),
      ),
      GoRoute(
        path: RoutePaths.LOGIN,
        name: RouteNames.LOGIN,
        builder: (_, __) => const _Placeholder(title: 'Login'),
      ),
      GoRoute(
        path: RoutePaths.REGISTER,
        name: RouteNames.REGISTER,
        builder: (_, __) => const _Placeholder(title: 'Register'),
      ),
      GoRoute(
        path: RoutePaths.HOME,
        name: RouteNames.HOME,
        builder: (_, __) => const _Placeholder(title: 'Home'),
      ),
      GoRoute(
        path: RoutePaths.SCHEDULE,
        name: RouteNames.SCHEDULE,
        builder: (_, __) => const _Placeholder(title: 'Schedule'),
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

class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

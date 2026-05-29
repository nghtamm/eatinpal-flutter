import 'package:flutter/material.dart';
import 'package:eatinpal/app/router/app_router.dart';
import 'package:eatinpal/core/constants/app_theme.dart';
import 'package:eatinpal/core/deeplink/deeplink_service.dart';
import 'package:eatinpal/core/di/service_locator.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final DeepLinkService _deeplink;

  @override
  void initState() {
    super.initState();
    _deeplink = di<DeepLinkService>()..init();
  }

  @override
  void dispose() {
    _deeplink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EatinPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router(),
    );
  }
}

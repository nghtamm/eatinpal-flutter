import 'package:flutter/material.dart';
import 'package:eatinpal/app/router/app_router.dart';
import 'package:eatinpal/core/constants/app_theme.dart';

class App extends StatelessWidget {
  App({super.key});

  final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EatinPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

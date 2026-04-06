import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eatinpal/app/router/app_router.dart';
import 'package:eatinpal/core/constants/app_theme.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/modules/auth/auth.dart';

class App extends StatelessWidget {
  App({super.key});

  final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'EatinPal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}

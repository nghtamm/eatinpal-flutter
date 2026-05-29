import 'package:eatinpal/app/app.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/di/service_locator.dart';
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
  runApp(const App());
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatinpal/app/app.dart';
import 'package:eatinpal/core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await initDependencies();
  runApp(App());
}

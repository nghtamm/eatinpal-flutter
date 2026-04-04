import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/api_client.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await _initCore();
  _initModules();
}

Future<void> _initCore() async {
  // Local Storage
  final storage = LocalStorageImpl();
  await storage.init();
  sl.registerSingleton<LocalStorage>(storage);

  // Network
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl<Dio>(), sl<LocalStorage>()),
  );
}

void _initModules() {
  _initAuth();
  _initTracking();
  _initSchedule();
}

void _initAuth() {
  // Services

  // Repositories

  // UseCases

  // Blocs
}

void _initTracking() {
  // Services

  // Repositories

  // UseCases

  // Blocs
}

void _initSchedule() {
  // Services

  // Repositories

  // UseCases

  // Blocs
}

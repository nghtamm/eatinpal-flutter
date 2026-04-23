import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/modules/auth/auth.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await _initCore();
  _initAuth();
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

void _initAuth() {
  // Services
  sl.registerLazySingleton(() => AuthService(sl<ApiClient>()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthService>(), sl<LocalStorage>()),
  );

  // Usecases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
    () => ResendVerificationUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton(() => VerifiedLoginUseCase(sl<AuthRepository>()));

  // Blocs
  sl.registerFactory(
    () => AuthBloc(
      register: sl<RegisterUseCase>(),
      login: sl<LoginUseCase>(),
      resendVerification: sl<ResendVerificationUseCase>(),
      verifiedLogin: sl<VerifiedLoginUseCase>(),
    ),
  );
}

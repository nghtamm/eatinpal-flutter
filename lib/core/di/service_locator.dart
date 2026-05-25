import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:eatinpal/app/router/app_router.dart';
import 'package:eatinpal/core/deeplink/deeplink_service.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/modules/auth/auth.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await _initCore();
  _initAuth();
}

Future<void> _initCore() async {
  // [LOCAL STORAGE]
  final storage = LocalStorageImpl();
  await storage.init();
  sl.registerSingleton<LocalStorage>(storage);

  // [NETWORK]
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl<Dio>(), sl<LocalStorage>()),
  );

  // [DEEP LINKING]
  sl.registerLazySingleton<AppLinks>(() => AppLinks());
  sl.registerLazySingleton<DeepLinkService>(
    () => DeepLinkService(navigatorKey, sl<AppLinks>(), sl<LocalStorage>()),
  );
}

void _initAuth() {
  // [SERVICES]
  sl.registerLazySingleton(() => AuthService(sl<ApiClient>()));

  // [REPOSITORIES]
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthService>(), sl<LocalStorage>()),
  );

  // [USECASES]
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
    () => ResendVerificationUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton(() => VerifyUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifiedLoginUseCase(sl<AuthRepository>()));

  // [BLOCS]
  sl.registerFactory(
    () => AuthBloc(
      register: sl<RegisterUseCase>(),
      login: sl<LoginUseCase>(),
      resendVerification: sl<ResendVerificationUseCase>(),
      verify: sl<VerifyUseCase>(),
      verifiedLogin: sl<VerifiedLoginUseCase>(),
    ),
  );
}

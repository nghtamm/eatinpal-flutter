import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:eatinpal/app/router/app_router.dart';
import 'package:eatinpal/core/deeplink/deeplink_service.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/modules/auth/auth.dart';
import 'package:get_it/get_it.dart';

final di = GetIt.instance;

Future<void> initDependencies() async {
  await _initCore();
  _initAuth();
}

Future<void> _initCore() async {
  // [LOCAL STORAGE]
  final storage = LocalStorageImpl();
  await storage.init();
  di.registerSingleton<LocalStorage>(storage);

  // [NETWORK]
  di.registerLazySingleton<Dio>(() => Dio());
  di.registerLazySingleton<ApiClient>(
    () => ApiClient(di<Dio>(), di<LocalStorage>()),
  );

  // [DEEP LINKING]
  di.registerLazySingleton<AppLinks>(() => AppLinks());
  di.registerLazySingleton<DeepLinkService>(
    () => DeepLinkService(navigatorKey, di<AppLinks>(), di<LocalStorage>()),
  );
}

void _initAuth() {
  // [SERVICES]
  di.registerLazySingleton(() => AuthService(di<ApiClient>()));

  // [REPOSITORIES]
  di.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(di<AuthService>(), di<LocalStorage>()),
  );

  // [USECASES]
  di.registerLazySingleton(() => LoginUseCase(di<AuthRepository>()));
  di.registerLazySingleton(() => RegisterUseCase(di<AuthRepository>()));
  di.registerLazySingleton(() => ResendUseCase(di<AuthRepository>()));
  di.registerLazySingleton(() => VerifyUseCase(di<AuthRepository>()));
  di.registerLazySingleton(() => MagicLinkUseCase(di<AuthRepository>()));
  di.registerLazySingleton(() => ForgotPasswordUseCase(di<AuthRepository>()));
  di.registerLazySingleton(() => VerifyOTPUseCase(di<AuthRepository>()));
  di.registerLazySingleton(() => ResetPasswordUseCase(di<AuthRepository>()));

  // [BLOCS]
  di.registerFactory(
    () => AuthBloc(
      register: di<RegisterUseCase>(),
      login: di<LoginUseCase>(),
      resend: di<ResendUseCase>(),
      verify: di<VerifyUseCase>(),
      magicLink: di<MagicLinkUseCase>(),
    ),
  );
  di.registerFactory(
    () => ForgotPasswordBloc(
      forgotPassword: di<ForgotPasswordUseCase>(),
      verifyOTP: di<VerifyOTPUseCase>(),
      resetPassword: di<ResetPasswordUseCase>(),
    ),
  );
}

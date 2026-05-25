---
name: state-management
description: flutter_bloc for state (events/states are regular classes + Equatable, NEVER freezed). get_it for DI (instance `sl`). go_router for navigation. fpdart `Either<AppException, T>` for fallible ops with `.fold((left), (right))`. NO Provider/Riverpod/MobX/Redux/GetX.
---

# Rule: State management, DI, routing, error flow

## Constraint

- **State management:** `flutter_bloc`. Events and states are regular classes with `Equatable`, override `props`. **NEVER `freezed` for BLoC.** Two styles — pick by state shape (see below).
- **DI:** `get_it`. Single global instance `sl` registered in `lib/core/di/service_locator.dart`. Resolve with `sl<T>()`. No `Provider`, `Riverpod`, `Bindings`, factory-singleton-by-hand.
- **Navigation:** `go_router` only. `context.go(...)`, `context.push(...)`, `context.pop(result)`, `context.pushReplacement(...)`. Routes in `lib/app/router/app_router.dart`; `RoutePaths` / `RouteNames` in `lib/app/router/route_names.dart`.
- **Dialogs / sheets / snackbars:** Flutter native (`showDialog`, `showModalBottomSheet`). For snackbars use the project's `AppSnackbar.success/info/warning/error(context, message)`. NO custom GetX-style wrappers.
- **Error flow:** Services return `Future<Either<AppException, ApiResult<T>>>`. Repositories unwrap `ApiResult` and return `Future<Either<AppException, T>>`. UseCases pass through. BLoC handlers `.fold((left), (right))` and emit appropriate state. **Always name fold params `left` / `right`** — NOT domain names. **Avoid `switch (result) { case Left ... case Right }`.**

## BLoC styles

### Style A — multi-class (default, for divergent state data)

Use when each state carries **different data**.

```dart
// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}
class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginSubmitted({required this.email, required this.password});
  @override List<Object?> get props => [email, password];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final String message;
  const AuthAuthenticated(this.message);
  @override List<Object?> get props => [message];
}
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override List<Object?> get props => [message];
}
```

### Style B — single-class with enum status (for shared fields)

Use when states share **most fields** and only differ by status (e.g., a list screen with items + pagination + status toggle).

```dart
enum FoodListStatus { INITIAL, LOADING, SUCCESS, FAILURE }

class FoodListState extends Equatable {
  final FoodListStatus status;
  final List<FoodEntity> items;
  final String? error;
  final int page;
  final bool hasReachedMax;

  const FoodListState({
    this.status = FoodListStatus.INITIAL,
    this.items = const [],
    this.error,
    this.page = 0,
    this.hasReachedMax = false,
  });

  FoodListState copyWith({
    FoodListStatus? status,
    List<FoodEntity>? items,
    String? error,
    int? page,
    bool? hasReachedMax,
  }) => FoodListState(
    status: status ?? this.status,
    items: items ?? this.items,
    error: error ?? this.error,
    page: page ?? this.page,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
  );

  @override
  List<Object?> get props => [status, items, error, page, hasReachedMax];
}
```

### Picking a style

| Condition | Style |
|---|---|
| States carry very different data shapes | A (multi-class) |
| States share most fields, differ by status | B (single-class) |
| Only 2-3 simple states | A (simpler) |
| Many fields persisted across status changes | B (avoids data loss) |

## Wiring DI

```dart
// lib/core/di/service_locator.dart
final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core
  sl.registerLazySingleton<LocalStorage>(() => LocalStorageImpl());
  await sl<LocalStorage>().init();
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Modules
  _registerAuthModule();
}

void _registerAuthModule() {
  sl
    ..registerLazySingleton<AuthService>(() => AuthService())
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => RegisterUseCase(sl()))
    ..registerFactory(() => AuthBloc(
          login: sl(),
          register: sl(),
          resendVerification: sl(),
          verify: sl(),
          verifiedLogin: sl(),
        ));
}
```

- Use `registerLazySingleton` for services, repositories, usecases — instance lives for app lifetime, created on first use.
- Use `registerFactory` for BLoCs — fresh instance per page so they dispose cleanly.

## Reading params from `go_router`

```dart
GoRoute(
  path: RoutePaths.VERIFY_EMAIL,
  name: RouteNames.VERIFY_EMAIL,
  builder: (context, state) {
    final args = state.extra as VerifyEmailArgs?;
    return VerifyEmailPage(args: args);
  },
),
```

## Service / Repository / UseCase / BLoC flow

```dart
// data/services/auth_service.dart
class AuthService {
  Future<Either<AppException, ApiResult<LoginResponseModel>>> login({
    required String email,
    required String password,
  }) {
    return sl<ApiClient>().request<LoginResponseModel>(
      method: RestMethod.POST,
      path: ApiEndpoints.LOGIN,
      data: {'email': email, 'password': password},
      parser: (data) => LoginResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }
}

// data/repository/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _service;
  final LocalStorage _storage;
  const AuthRepositoryImpl(this._service, this._storage);

  @override
  Future<Either<AppException, String>> login({
    required String email,
    required String password,
  }) async {
    final result = await _service.login(email: email, password: password);
    return result.fold((left) async => Left(left), (right) async {
      await _storage.saveCredentialsToken(
        accessToken: right.data.tokens.accessToken,
        refreshToken: right.data.tokens.refreshToken,
      );
      return Right(right.message);
    });
  }
}

// domain/usecases/login_usecase.dart
class LoginParams extends Equatable {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
  @override List<Object?> get props => [email, password];
}

class LoginUseCase implements UseCase<String, LoginParams> {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(LoginParams params) =>
      _repository.login(email: params.email, password: params.password);
}

// presentation/bloc/auth_bloc.dart
Future<void> _onLogin(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
  emit(const AuthLoading());
  final result = await _login(
    LoginParams(email: event.email, password: event.password),
  );
  result.fold(
    (left) => emit(AuthFailure(left.message)),
    (right) => emit(AuthAuthenticated(right)),
  );
}
```

Note: `single-field` usecase params skip the wrapper class — pass the primitive directly:

```dart
class ResendVerificationUseCase implements UseCase<String, String> {
  final AuthRepository _repository;
  const ResendVerificationUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(String email) =>
      _repository.resendVerification(email: email);
}
```

## Reading state in a page

```dart
return BlocListener<AuthBloc, AuthState>(
  listener: _onStateChanged,
  child: BlocBuilder<AuthBloc, AuthState>(
    buildWhen: (prev, curr) => (prev is AuthLoading) != (curr is AuthLoading),
    builder: (_, state) => LoadingOverlay(
      isLoading: state is AuthLoading,
      child: /* ... */,
    ),
  ),
);

void _onStateChanged(BuildContext context, AuthState state) {
  if (state is AuthAuthenticated) {
    AppSnackbar.success(context, state.message);
    context.go(RoutePaths.HOME);
  } else if (state is AuthFailure) {
    AppSnackbar.error(context, state.message);
  }
}
```

- `BlocListener` for side effects (snackbar, navigation).
- `BlocBuilder` with `buildWhen` for selective rebuilds (perf).

## ❌ Forbidden

```dart
@freezed                                                       // ❌
class AuthState with _$AuthState { ... }

Provider.of<AuthBloc>(context, listen: false);                 // ❌ — use BlocProvider + context.read
sl.registerSingleton(AuthBloc(...));                           // ❌ — BLoCs are registerFactory
Get.find<AuthBloc>();                                          // ❌ — no GetX

switch (result) {                                              // ❌ — use .fold((left), (right))
  case Left(:final value): ...;
  case Right(:final value): ...;
}

final loginResult = result.fold(                               // ❌ — params named after domain
  (failure) => emit(AuthFailure(failure.message)),
  (token) => emit(AuthAuthenticated(token)),
);
```

## ✅ Correct

```dart
result.fold(
  (left) => emit(AuthFailure(left.message)),                   // ✅ left/right
  (right) => emit(AuthAuthenticated(right)),
);
```

## Closing pages, dialogs, sheets

| Closing… | Use |
|---|---|
| Dialog from `showDialog(...)` | `context.pop(result)` from inside the builder |
| Bottom sheet from `showModalBottomSheet(...)` | `context.pop(result)` |
| Page (back) | `context.pop(result)` |

## See also

- `docs/03-state-routing.md` — full narrative: bloc styles, go_router, dialogs, deep links
- `docs/04-networking.md` § `Either<AppException, ApiResult<T>>` contract
- `lib/modules/auth/` — full reference implementation
- `.claude/rules/modular-structure.md` — DI registration per module
- `.claude/rules/code-generators.md` — why BLoC stays hand-written

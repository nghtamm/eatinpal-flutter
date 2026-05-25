# State management & routing

The deep reference for how state and navigation work in this codebase. Covers `flutter_bloc` patterns (two styles), `get_it` registration & resolution, `go_router` as the single navigator, dialog / sheet / snackbar APIs, deep links, and the auth guard.

## The scope of each package

| Package | Used for |
|---|---|
| `flutter_bloc` | All reactive state. BLoCs orchestrate UseCases → emit states. |
| `equatable` | `Equatable` mixin on events / states for value equality + correct rebuild semantics. |
| `get_it` | Dependency injection — single instance `sl` in `core/di/service_locator.dart`. |
| `go_router` | All navigation — `context.go`, `context.push`, `context.pop`, `context.replace`, `context.goNamed`. |

**Forbidden** in this project:
- `Provider`, `Riverpod`, `MobX`, `Redux`, `GetX` (any part of it).
- `Navigator.of(context).pushNamed(...)` for route navigation — use `go_router` APIs instead. `Navigator.of(ctx).pop(...)` IS fine for closing a dialog opened with `showDialog`.
- `freezed` for BLoC events / states (allowed only for data models in `data/models/`).

## State management — `flutter_bloc`

### Anatomy

A module's presentation layer has three files in `bloc/`:

- `<name>_bloc.dart` — `extends Bloc<Event, State>`, takes usecases via constructor injection, registers `on<Event>` handlers.
- `<name>_event.dart` — `abstract class <Name>Event extends Equatable` + concrete sub-classes. `props` returns the fields that matter for equality.
- `<name>_state.dart` — `abstract class <Name>State extends Equatable` + concrete sub-classes (Style A) OR a single class with an enum status (Style B). `props` covers every meaningful field.

### Two styles — pick based on the state shape

#### Style A — Multi-class (DEFAULT, for divergent state shapes)

Use when each state carries **different data** — e.g. auth: `Initial` carries nothing, `Loading` carries nothing, `Success` carries a message, `Authenticated` carries a message, `Failure` carries a message.

Real example from `lib/modules/auth/presentation/bloc/auth_state.dart`:

```dart
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final String message;
  const AuthSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final String message;
  const AuthAuthenticated(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRequiresVerification extends AuthState {
  final String message;
  const AuthRequiresVerification(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
```

Events (also multi-class):

```dart
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthResendVerificationRequested extends AuthEvent {
  final String email;
  const AuthResendVerificationRequested(this.email);

  @override
  List<Object?> get props => [email];
}
```

Bloc:

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase _register;
  final LoginUseCase _login;
  final ResendVerificationUseCase _resendVerification;
  final VerifyUseCase _verify;
  final VerifiedLoginUseCase _verifiedLogin;

  AuthBloc({
    required RegisterUseCase register,
    required LoginUseCase login,
    required ResendVerificationUseCase resendVerification,
    required VerifyUseCase verify,
    required VerifiedLoginUseCase verifiedLogin,
  })  : _register = register,
        _login = login,
        _resendVerification = resendVerification,
        _verify = verify,
        _verifiedLogin = verifiedLogin,
        super(const AuthInitial()) {
    on<AuthRegisterSubmitted>(_onRegister);
    on<AuthLoginSubmitted>(_onLogin);
    on<AuthResendVerificationRequested>(_onResendVerification);
    on<AuthVerifyFromLinkRequested>(_onVerifyFromLink);
  }

  Future<void> _onLogin(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (left) {
        if (left is ForbiddenException) {
          emit(AuthRequiresVerification(left.message));
        } else {
          emit(AuthFailure(left.message));
        }
      },
      (right) => emit(AuthAuthenticated(right)),
    );
  }

  // ... other handlers
}
```

#### Style B — Single-class with enum status (for shared fields)

Use when states share **most fields** and only differ by status — e.g. a list screen that always has `items` + `page` + `hasMore`, status just toggles loading / loaded / failure.

```dart
enum FoodListStatus { INITIAL, LOADING, SUCCESS, FAILURE }

class FoodListState extends Equatable {
  final FoodListStatus status;
  final List<FoodEntity> items;
  final String? error;
  final int page;
  final bool hasMore;

  const FoodListState({
    this.status = FoodListStatus.INITIAL,
    this.items = const [],
    this.error,
    this.page = 0,
    this.hasMore = true,
  });

  FoodListState copyWith({
    FoodListStatus? status,
    List<FoodEntity>? items,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return FoodListState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [status, items, error, page, hasMore];
}
```

Note: the enum values are `UPPER_SNAKE_CASE` per the naming rule (`RestMethod.GET`, `AppSnackbarType.SUCCESS`, etc.). Reach for hand-written `copyWith` — NO freezed.

#### Quick decision

| Condition | Style |
|---|---|
| States carry very different data shapes | A (multi-class) |
| States share most fields, differ by status | B (single-class) |
| Only 2-3 simple states | A (simpler) |
| Many fields persisted across status changes | B (avoids data loss in transitions) |

### Wiring with `BlocProvider`

Pages provide their BLoC via `BlocProvider` and resolve from `get_it`:

```dart
class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _AuthenticationView(),
    );
  }
}
```

Because `AuthBloc` is registered with `sl.registerFactory(...)`, each `sl<AuthBloc>()` call yields a NEW instance — re-entering the page resets state.

For consumers:

- **`BlocBuilder<Bloc, State>`** — rebuilds widget on every emission. Use for the main reactive UI.
- **`BlocListener<Bloc, State>`** — fires a side-effect (snackbar, navigation) on emission without rebuilding. Use for one-shot reactions.
- **`BlocConsumer<Bloc, State>`** — both, in one widget. Use when the same state drives both UI and a side-effect.

```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
    } else if (state is AuthAuthenticated) {
      context.go(RoutePaths.HOME);
    }
  },
  builder: (context, state) {
    final loading = state is AuthLoading;
    return AppButton(
      label: 'Sign in',
      onPressed: loading ? null : _submit,
    );
  },
)
```

`AppButton` only takes `label`, `onPressed`, `variant`, `height` — there is no `isLoading` prop. To indicate work in progress, EITHER (a) set `onPressed: null` (button auto-greys via `disabledBackgroundColor`) OR (b) wrap the page in `LoadingOverlay` and emit a modal scrim — see § `LoadingOverlay`.

### `buildWhen` / `listenWhen`

Reduce unnecessary rebuilds by predicating the emission. Real pattern from `LoginPage._LoginViewState.build`:

```dart
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (prev, curr) => (prev is AuthLoading) != (curr is AuthLoading),
  builder: (_, state) => LoadingOverlay(
    isLoading: state is AuthLoading,
    child: Scaffold(...),
  ),
)
```

Only rebuild when `AuthLoading` ↔ non-`AuthLoading` transition happens. Saves rebuilds on every intermediate state (e.g. `AuthInitial → AuthLoading → AuthAuthenticated`).

### Stream subscription discipline

A `Bloc` auto-closes on `BlocProvider` dispose. If you subscribe to a `Stream` inside the BLoC (e.g. connectivity changes), you MUST cancel the subscription in `close()`:

```dart
class FoodListBloc extends Bloc<FoodListEvent, FoodListState> {
  StreamSubscription<bool>? _connectivitySub;

  FoodListBloc({...}) : super(const FoodListState()) {
    _connectivitySub = Connectivity().changes.listen((online) {
      if (online) add(const FoodListRefreshed());
    });
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
```

## Dependency injection — `get_it`

The single instance `sl` lives in `lib/core/di/service_locator.dart`. Everything registered there is resolvable from anywhere via `sl<T>()`.

### Registration patterns

| Pattern | Use | Lifetime |
|---|---|---|
| `sl.registerSingleton<T>(instance)` | Async-initialised singleton (e.g. `LocalStorageImpl` after `await storage.init()`) | One instance forever |
| `sl.registerLazySingleton<T>(() => ...)` | Default for services, repositories, usecases, `ApiClient`, `Dio` | One instance, created on first `sl<T>()` |
| `sl.registerFactory<T>(() => ...)` | BLoCs (new instance per `sl<AuthBloc>()` call, so state resets on page re-entry) | New instance every call |

### Resolution

```dart
// In a page's BlocProvider:
BlocProvider(create: (_) => sl<AuthBloc>(), child: ...)

// In a one-off (e.g. router guard, deep-link handler):
final signed = await sl<LocalStorage>().signed;
```

Never resolve inside a `build(...)` method — it's a code smell. Resolve at the entry point (page, router, BLoC constructor) and pass via constructor / `BlocProvider`.

### Adding a new module's registration

In `service_locator.dart`, add a private `_init<Module>()` function and call it from `initDependencies()`:

```dart
Future<void> initDependencies() async {
  await _initCore();
  _initAuth();
  _initFood();           // ← new
}

void _initFood() {
  sl.registerLazySingleton(() => FoodService(sl<ApiClient>()));
  sl.registerLazySingleton<FoodRepository>(
    () => FoodRepositoryImpl(sl<FoodService>()),
  );
  sl.registerLazySingleton(() => GetFoodListUseCase(sl<FoodRepository>()));
  sl.registerFactory(() => FoodListBloc(getList: sl<GetFoodListUseCase>()));
}
```

Order matters within a module: service → repository → usecase → bloc.

## Navigation — `go_router`

### Route table

Defined in `lib/app/router/app_router.dart`. Path + name constants in `lib/app/router/route_names.dart`:

```dart
abstract final class RouteNames {
  static const String AUTHENTICATION = 'authentication';
  static const String LOGIN = 'login';
  // ...
}

abstract final class RoutePaths {
  static const String AUTHENTICATION = '/authentication';
  static const String LOGIN = '/login';
  // ...
}
```

Both classes are `abstract final class` (Dart 3.0+ — prevents `extends`, `implements`, `with` AND instantiation). `UPPER_SNAKE_CASE` field values.

### Navigation APIs

| API | Purpose |
|---|---|
| `context.go(RoutePaths.HOME)` | Replace stack with this route — typical post-login / logout |
| `context.push(RoutePaths.DETAIL)` | Push onto stack — back button returns |
| `context.pushReplacement(...)` | Push + remove current |
| `context.replace(RoutePaths.X)` | Replace current entry |
| `context.pop()` / `context.pop(result)` | Pop with optional result |
| `context.goNamed(RouteNames.LOGIN)` | Same as `go`, named lookup |
| `context.pushNamed(...)` | Same as `push`, named lookup |

For passing data, use `state.extra` (in-memory, dies on cold-start) or path / query params (survive cold-start):

```dart
context.push(RoutePaths.VERIFY_EMAIL, extra: VerifyEmailArgs(email: ..., autoResend: false));

// In the route builder:
GoRoute(
  path: RoutePaths.VERIFY_EMAIL,
  name: RouteNames.VERIFY_EMAIL,
  builder: (_, state) => VerifyEmailPage(args: state.extra as VerifyEmailArgs?),
),
```

If a value must survive cold-start (deep links), put it in path or query — never in `extra`. The cold-start magic-link flow demonstrates the alternative: stash it in `LocalStorage.saveVerificationToken(token)` before `runApp`, read it inside the page, then call `clearVerificationToken()`.

### Auth guard

Single source of truth — `_guard(...)` in `app_router.dart`. Runs on every navigation, including cold-start.

```dart
const _DEST_AUTH = {
  RoutePaths.AUTHENTICATION,
  RoutePaths.REGISTER,
  RoutePaths.LOGIN,
  RoutePaths.VERIFY_EMAIL,
  RoutePaths.VERIFICATION_SUCCESS,
};

Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final signed = await sl<LocalStorage>().signed;
  final destAuth = _DEST_AUTH.contains(state.matchedLocation);

  if (signed && destAuth) return RoutePaths.HOME;       // logged-in user can't view auth pages
  if (!signed && !destAuth) return RoutePaths.AUTHENTICATION;  // logged-out user → bounce to auth
  return null;
}
```

Customise `_DEST_AUTH` and add role-based gates here as the product grows. This is one of the few places where editing the file in `lib/app/router/` is normal product work — but the structure (single guard, returns `String?`, async) is hands-off.

### Why one navigator

Mixing two navigation systems leads to:

- Guards bypassed — protected routes leak when one navigator doesn't fire `redirect`.
- Broken deep links — `go_router`'s URL ↔ stack mapping desyncs.
- Confused `BackButtonDispatcher` — system back can pop the wrong navigator.

`go_router` is the single navigator. `Navigator.of(context).pop(...)` is OK only for dialogs / sheets opened with `showDialog` / `showModalBottomSheet`.

## Dialogs, sheets, snackbars

All three use Flutter / `ScaffoldMessenger` APIs — or the project's `AppSnackbar` wrapper.

### Dialog — `showDialog`

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Confirm delete'),
    content: const Text('This cannot be undone.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(false),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(true),
        child: const Text('Delete'),
      ),
    ],
  ),
);
```

Close with `Navigator.of(dialogContext).pop(result)` or `context.pop(result)` from inside the builder.

For destructive confirms, set `barrierDismissible: false` to require an explicit tap.

### Bottom sheet — `showModalBottomSheet`

```dart
await showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: const _FilterSheet(),
  ),
);
```

`isScrollControlled: true` lets the sheet expand to full height (otherwise it caps at ~50% screen). The `viewInsets.bottom` padding keeps the keyboard from covering inputs.

### Snackbar — `AppSnackbar`

The project ships `lib/core/widgets/app_snackbar.dart` — a wrapper around `ScaffoldMessenger.of(context).showSnackBar(...)` with brand styling.

Four convenience constructors:

```dart
AppSnackbar.success(context, 'Saved!');
AppSnackbar.info(context, 'Heads up — your session expires soon.');
AppSnackbar.warning(context, 'Couldn\'t reach the server. Showing cached data.');
AppSnackbar.error(context, 'Sign-in failed. Please try again.');

// Full form (custom type / duration):
AppSnackbar.show(
  context,
  message: 'Custom',
  type: AppSnackbarType.SUCCESS,
  duration: const Duration(seconds: 5),
);
```

The `AppSnackbarType` enum values are `UPPER_SNAKE_CASE`: `SUCCESS`, `INFO`, `WARNING`, `ERROR`. Each maps to an icon + accent color.

`AppSnackbar.show` calls `ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(...)` — only one snackbar visible at a time. Don't stack them.

Duration default: 3 s. Bump to 6 s when including a retry action.

### `LoadingOverlay`

For blocking operations (sign-in, submit), the project provides `lib/core/widgets/loading_overlay.dart`. It is a WRAPPER widget — wrap the page content and toggle `isLoading` from BLoC state:

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (ctx, state) {
    return LoadingOverlay(
      isLoading: state is AuthLoading,
      child: Scaffold(
        appBar: const BasicAppBar(title: Text('Sign in')),
        body: ...,
      ),
    );
  },
)
```

`LoadingOverlay` does three things while `isLoading`:
- `PopScope(canPop: false)` blocks the system back button so the user can't accidentally pop mid-request.
- `AbsorbPointer` swallows all taps on the child.
- A scrim (`barrierColor`, default `AppColors.SCRIM`) covers the child, with a centred `AppCircularProgress` spinner painted on top.

For a smaller / inline spinner without the modal scrim, use `AppCircularProgress` directly:

```dart
const AppCircularProgress(size: 24, strokeWidth: 3, color: AppColors.PRIMARY)
```

## `BlocProvider` lifecycle

A `BlocProvider` creates the BLoC on widget mount and disposes it (`bloc.close()`) on unmount. With `registerFactory`, a fresh BLoC is created per `BlocProvider` creation — so re-entering a page resets state.

### Cross-page state sharing

Don't reach for another module's BLoC from outside its provider scope. If state must persist across pages (e.g. current user, current cart):

1. **Store in `LocalStorage`** — for auth tokens (already done) and small persistent state.
2. **Share via a `Repository` singleton** — registered with `registerLazySingleton`, multiple BLoCs / pages depend on it.
3. **Lift the `BlocProvider`** to a parent route or app-level — `MultiBlocProvider` at `AppRoot`. Use sparingly; turn into a `GlobalProvider`-like pattern only when truly app-wide (session BLoC, theme BLoC).

```dart
// In app.dart (only if truly app-wide):
return MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => sl<SessionBloc>()),
  ],
  child: MaterialApp.router(...),
);
```

For one-shot parent ← child return value, use `context.push<T>(...)` + `context.pop<T>(value)`. No shared state needed.

## Deep links — `app_links`

This codebase handles deep links via the `app_links` package + a custom `DeepLinkService` (`lib/core/deeplink/deeplink_service.dart`).

### Cold-start

Resolved in `main.dart` BEFORE `runApp`:

```dart
Future<String> _determineInitialRoute() async {
  final link = await sl<AppLinks>().getInitialLink();
  if (link == null || !link.path.endsWith('/auth/verify')) {
    return RoutePaths.AUTHENTICATION;
  }
  final token = link.queryParameters['token'];
  if (token == null || token.isEmpty) return RoutePaths.AUTHENTICATION;
  final storage = sl<LocalStorage>();
  if (await storage.signed) return RoutePaths.HOME;
  if (isJWTExpired(token)) return RoutePaths.AUTHENTICATION;

  // Cold-start carrier: go_router không hỗ trợ initialExtra,
  // dùng storage làm bridge một lần. VerificationSuccessPage sẽ đọc + clear.
  await storage.saveVerificationToken(token);
  return RoutePaths.VERIFICATION_SUCCESS;
}
```

Pattern: inspect the link, decide the initial route, possibly stash a one-shot value in `LocalStorage` (since `go_router` doesn't support `initialExtra`). The destination page reads + clears it.

### Warm-start

`DeepLinkService` subscribes to `AppLinks().uriLinkStream` in its `init()`. On a new URI, it inspects the path and calls `navigatorKey.currentContext?.go(...)` to route. `init()` is called from `_AppState.initState()`; `dispose()` is called from `_AppState.dispose()` (cancels the subscription).

For new deep-link routes:

1. Add the path + name constant to `RoutePaths` / `RouteNames`.
2. Add the route block to `app_router.dart`.
3. Extend `DeepLinkService._handleLink(Uri uri)` (or equivalent) with the new path matcher.
4. Extend `main.dart`'s `_determineInitialRoute()` if the link should work from cold-start.
5. Wire native intent filters / Universal Links — `android/app/src/main/AndroidManifest.xml` + `ios/Runner/Info.plist` + `ios/Runner/Runner.entitlements`.

## Reactive controller patterns

### BLoC handler — fpdart Either dispatch

Standard handler shape:

```dart
Future<void> _onLogin(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
  emit(const AuthLoading());
  final result = await _login(LoginParams(email: event.email, password: event.password));
  result.fold(
    (left) => emit(AuthFailure(left.message)),
    (right) => emit(AuthAuthenticated(right)),
  );
}
```

Always check what subtype `left` is before deciding the state — different `AppException` subclasses might map to different UX states:

```dart
result.fold(
  (left) {
    if (left is ForbiddenException) {
      emit(AuthRequiresVerification(left.message));
    } else {
      emit(AuthFailure(left.message));
    }
  },
  (right) => emit(AuthAuthenticated(right)),
);
```

### Sequential calls in one handler

Real example from `AuthBloc._onVerifyFromLink`:

```dart
Future<void> _onVerifyFromLink(
  AuthVerifyFromLinkRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());

  final verifyResult = await _verify(event.token);
  final verifyFailure = verifyResult.fold<AppException?>(
    (left) => left,
    (_) => null,
  );
  if (verifyFailure != null) {
    emit(AuthFailure(verifyFailure.message));
    return;
  }

  final loginResult = await _verifiedLogin(event.token);
  loginResult.fold(
    (left) => emit(AuthFailure(left.message)),
    (right) => emit(AuthAuthenticated(right)),
  );
}
```

Pattern: fold to a `T?` to bail early, then chain the next call.

## Common pitfalls

- **Using `Navigator.pushNamed(...)`** — bypasses `go_router` guards. Use `context.go(...)` / `context.push(...)`.
- **Mounting a `BlocProvider` at the wrong level** — child can't find the BLoC. Provide as close to the consuming tree as possible, but above all consumers.
- **Resolving `sl<Bloc>()` inside `build(...)`** — creates a new BLoC every rebuild (since registered factory). Resolve once at the entry point.
- **Reaching another module's BLoC** — out of provider scope = `ProviderNotFoundException`. Share via a singleton `Repository` or lift the provider.
- **Forgetting `props` on an `Equatable` event/state** — `bloc.emit` won't fire because `next == current`. Always override `props`.
- **Using freezed on a BLoC event/state** — forbidden by the `bloc-no-freezed` rule.
- **Storing `BuildContext` in the BLoC** — fragile across navigation, hot reload. Pass context from button handlers.
- **No `context.mounted` check after `await` in a UI callback** — "use of disposed BuildContext" crash. Always guard:
  ```dart
  await _bloc.submit();
  if (!context.mounted) return;
  context.go(RoutePaths.HOME);
  ```
- **`AppSnackbar.show` from inside a BLoC handler** — BLoCs don't have a `BuildContext`. Use a `BlocListener` in the page to call `AppSnackbar.error(context, state.message)` on `AuthFailure`.

## See also

- `01-architecture.md` — composition root (`service_locator.dart`, `app_router.dart`), bootstrap order
- `04-networking.md` — `Either<AppException, T>` contract, interceptors
- `05-clean-architecture.md` — usecase → repository flow that BLoCs call
- `06-modules.md` — feature build flow including the BLoC wiring step
- `07-theming-ui.md` — `AppSnackbar`, `LoadingOverlay`, dialog patterns
- `08-platform.md` — `app_links` native config (Universal Links / App Links)
- `CLAUDE.md` § Critical rules — rules 4 (BLoC never freezed), 8 (state + routing)
- `lib/core/di/service_locator.dart` — full DI tree
- `lib/app/router/app_router.dart` — current routes + guard
- `lib/modules/auth/presentation/bloc/auth_bloc.dart` — full Style A example

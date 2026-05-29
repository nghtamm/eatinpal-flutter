# Architecture

The detailed reference for how the EatinPal codebase is laid out, the layering rules between `core/` and `modules/`, what the composition root is, the bootstrap sequence, and which files are hands-off (and why).

## Folder layout

```
lib/
├── main.dart                                       # bootstrap entry
├── app/
│   ├── app.dart                                    # AppRoot — MaterialApp.router + theme + deep-link lifecycle
│   └── router/
│       ├── app_router.dart                         # NOT hands-off (router config) — but _guard logic is hands-off until product gating changes
│       └── route_names.dart                        # NOT hands-off — add path / name constants freely
│
├── core/                                           # framework / cross-cutting; NO barrel
│   ├── constants/                                  # NOT hands-off — add tokens freely
│   │   ├── app_colors.dart                         # AppColors — brand, neutral, semantic, surface, common
│   │   ├── app_fonts.dart                          # AppFonts — Inter, Epilogue families
│   │   ├── app_spacing.dart                        # AppPadding + AppRadius + SIZED_BOX_* + SPACE_ZERO / SPACER
│   │   ├── app_theme.dart                          # AppTheme.light composition from tokens
│   │   └── app_typography.dart                     # AppTypography — M3-style hierarchy
│   │
│   ├── deeplink/
│   │   └── deeplink_service.dart                   # NOT hands-off (logic per project) — but init/dispose contract is hands-off
│   │
│   ├── di/
│   │   └── service_locator.dart                    # Hands-off (registration ordering) — modules add their `_init<Module>()` only with approval
│   │
│   ├── helpers/                                    # NOT hands-off — add freely
│   │   ├── extensions.dart
│   │   ├── jwt.dart                                # isJWTExpired
│   │   └── validators.dart
│   │
│   ├── local/
│   │   └── local_storage.dart                      # Hands-off — LocalStorage interface + LocalStorageImpl
│   │
│   ├── network/
│   │   ├── api_client.dart                         # Hands-off — Dio wrapper + envelope unwrap
│   │   ├── api_endpoints.dart                      # NOT hands-off — add endpoint constants any time
│   │   ├── api_methods.dart                        # Hands-off — RestMethod enum
│   │   ├── api_result.dart                         # Hands-off — ApiResult<T> envelope record
│   │   ├── error_handler.dart                      # Hands-off — DioException → AppException mapping
│   │   ├── exceptions.dart                         # Hands-off — AppException hierarchy
│   │   ├── protocol_type.dart                      # Hands-off
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart               # Hands-off — silent refresh-token rotation
│   │       └── logging_interceptor.dart            # NOT hands-off (formatting tweaks ok)
│   │
│   ├── usecase/
│   │   └── usecase.dart                            # Hands-off — UseCase<T, Params> / UseCaseNoParams<T> / NoParams
│   │
│   └── widgets/                                    # NOT hands-off — cross-module widgets
│       ├── app_button.dart                         # AppButton with AppButtonVariant.PRIMARY/SECONDARY/DANGER
│       ├── app_snackbar.dart                       # AppSnackbar.success/info/warning/error
│       ├── basic_appbar.dart
│       └── loading_overlay.dart
│
└── modules/                                        # one folder per feature; NO top-level barrel
    └── auth/                                       # sample full-clean-arch module
        ├── auth.dart                               # MANDATORY per-module barrel
        ├── data/
        │   ├── models/
        │   │   ├── user_model.dart                 # freezed, implements UserEntity
        │   │   ├── user_model.freezed.dart         # generated — committed
        │   │   ├── user_model.g.dart               # generated — committed
        │   │   ├── credentials_model.dart
        │   │   ├── credentials_model.freezed.dart
        │   │   └── credentials_model.g.dart
        │   ├── services/
        │   │   └── auth_service.dart               # ApiClient calls, returns Either<AppException, ApiResult<T>>
        │   └── repository/
        │       └── auth_repository_impl.dart       # wraps service, persists tokens to LocalStorage
        ├── domain/
        │   ├── entities/
        │   │   └── user_entity.dart                # plain Dart class
        │   ├── repository/
        │   │   └── auth_repository.dart            # abstract — returns Either<AppException, T>
        │   └── usecases/
        │       ├── login_usecase.dart              # multi-field params class
        │       ├── register_usecase.dart
        │       ├── resend_usecase.dart # single-field — takes String directly (no wrapper)
        │       ├── verify_usecase.dart
        │       └── magic_link_usecase.dart
        └── presentation/
            ├── bloc/
            │   ├── auth_bloc.dart                  # extends Bloc<AuthEvent, AuthState>
            │   ├── auth_event.dart                 # Equatable, multi-class
            │   └── auth_state.dart                 # Equatable, multi-class (Style A)
            ├── pages/
            │   ├── authentication_page.dart
            │   ├── login_page.dart
            │   ├── register_page.dart
            │   ├── verify_email_page.dart
            │   ├── verification_success_page.dart
            │   └── homepage.dart
            └── widgets/
                ├── auth_textfield.dart
                └── password_strength.dart
```

Every feature lives at `lib/modules/<name>/`. Three mandatory sub-folders:

- **`data/`** — `models/` (freezed + json_serializable, extends entity), `services/` (calls `ApiClient`, returns `Either<AppException, ApiResult<T>>`), `repository/` (`<name>_repository_impl.dart` — wraps services, returns `Either<AppException, T>`).
- **`domain/`** — `entities/` (plain Dart classes; equatable optional), `repository/` (abstract interface), `usecases/` (extend `UseCase<T, Params>` or `UseCaseNoParams<T>`).
- **`presentation/`** — `bloc/` (`<name>_bloc.dart` + `<name>_event.dart` + `<name>_state.dart` with `Equatable`), `pages/`, `widgets/` (module-scoped only).

## Layering rules

The codebase enforces a strict dependency direction:

```
presentation/ (BLoC + pages + widgets)
        ↓
domain/ (usecases → repository interface → entities)
        ↓
data/ (repository_impl → service → ApiClient)
        ↓
core/<area>/ → external packages
```

| From | To | Allowed |
|---|---|---|
| `modules/<X>/presentation/` | `modules/<X>/domain/` | ✅ |
| `modules/<X>/domain/` | `modules/<X>/data/` | ❌ — `domain` knows nothing about `data` |
| `modules/<X>/data/` | `modules/<X>/domain/` | ✅ — `data` implements `domain` interfaces |
| `modules/<X>/data/` | `modules/<X>/presentation/` | ❌ |
| `modules/<X>/` | `core/` | ✅ |
| `core/<X>/` | `core/<Y>/` | ✅ |
| `lib/main.dart` / `lib/app/` | anything | ✅ (composition root) |
| `lib/core/di/service_locator.dart` | `modules/<X>/<X>.dart` (barrel only) | ✅ (composition root for DI) |
| `modules/A/` | `modules/B/` | ❌ |
| `core/<X>/` (any other) | `modules/` | ❌ |

### Why these rules

**Modules don't import each other** because:

- Cross-module coupling makes "delete this feature" become "rewrite five other features".
- BLoCs are factory-scoped via `di.registerFactory(...)` — reaching for another module's BLoC via `BlocProvider.of` from outside its provider scope throws.
- It forces shared logic to be lifted to `core/` (widgets, helpers, constants) or modelled as a shared service / repository registered as a singleton.

**`domain/` does NOT import `data/`** because:

- The whole point of Clean Architecture is that `domain/` is the pure-Dart business core, with NO dependency on frameworks or external types.
- `data/models/` implements `domain/entities/` and `data/repository/` implements `domain/repository/` — the dependency arrow points INTO domain.

**Core does not import modules** because:

- `core/` is the framework. If `core/network/` imported `modules/auth/`, you couldn't reuse `ApiClient` in any other module without dragging `auth/` along.
- The one exception (`core/di/service_locator.dart`) is the composition root — its job IS to know every module so it can wire DI.

### What goes in `core/widgets/`

Widgets used by ≥ 2 modules. Currently: `AppButton`, `AppSnackbar`, `BasicAppBar`, `LoadingOverlay`. Add new widgets here when the second module needs them.

What does NOT go in `core/widgets/`:

- Module-specific widgets (an auth-only text field with password-strength meter) → keep in `modules/auth/presentation/widgets/`.
- Theme tokens → those belong in `core/constants/`.
- Validators / helpers → those belong in `core/helpers/`.

## Composition root

`lib/main.dart` + `lib/app/app.dart` + `lib/core/di/service_locator.dart` + `lib/app/router/app_router.dart` together form the composition root — the only locations allowed to know about every module.

### `service_locator.dart` — DI wiring

```dart
final di = GetIt.instance;

Future<void> initDependencies() async {
  await _initCore();
  _initAuth();
  // Add _init<Module>() calls here as new modules ship.
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
  di.registerLazySingleton(() => AuthService(di<ApiClient>()));
  di.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(di<AuthService>(), di<LocalStorage>()),
  );
  di.registerLazySingleton(() => LoginUseCase(di<AuthRepository>()));
  // ... other usecases
  di.registerFactory(() => AuthBloc(
        register: di<RegisterUseCase>(),
        login: di<LoginUseCase>(),
        // ...
      ));
}
```

Pattern per module:
- `Service` → `registerLazySingleton` (depends on `ApiClient`).
- `Repository` → `registerLazySingleton` (depends on `Service` + maybe `LocalStorage`).
- `UseCase` → `registerLazySingleton` (depends on `Repository`).
- `Bloc` → `registerFactory` (depends on usecases — NEW instance per page so state resets on re-entry).

### `app_router.dart` — route + guard wiring

```dart
final navigatorKey = GlobalKey<NavigatorState>();

const _DEST_AUTH = {
  RoutePaths.AUTHENTICATION,
  RoutePaths.REGISTER,
  RoutePaths.LOGIN,
  RoutePaths.VERIFY_EMAIL,
  RoutePaths.VERIFICATION_SUCCESS,
};

GoRouter router() {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RoutePaths.AUTHENTICATION,
    redirect: _guard,
    routes: [
      GoRoute(path: RoutePaths.AUTHENTICATION, name: RouteNames.AUTHENTICATION, builder: (_, __) => const AuthenticationPage()),
      GoRoute(path: RoutePaths.LOGIN,         name: RouteNames.LOGIN,         builder: (_, __) => const LoginPage()),
      // ...
    ],
  );
}

Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final signed = await di<LocalStorage>().signed;
  final destAuth = _DEST_AUTH.contains(state.matchedLocation);
  if (signed && destAuth)   return RoutePaths.HOME;
  if (!signed && !destAuth) return RoutePaths.AUTHENTICATION;
  return null;
}
```

`navigatorKey` is exported so `DeepLinkService` can call `currentContext.go(...)` for warm-start deep links.

`_guard` is the single source of truth for "can the user access this route?". Every navigation goes through `go_router` (no other navigator API allowed), so the guard runs for cold-start deep links, in-app pushes, back-stack pops alike.

## Bootstrap order

`lib/main.dart` runs initialisation in a fixed sequence. Reordering breaks things.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();      // 1. Flutter binding
  SystemChrome.setSystemUIOverlayStyle(...);      // 2. Status bar styling
  await dotenv.load();                            // 3. .env loaded — BASE_URL needed before ApiClient
  await initDependencies();                       // 4. DI — registers LocalStorage (with init), Dio, ApiClient, DeepLinkService, auth tree
  runApp(const App());                            // 5. MaterialApp.router; guard decides landing route
}
```

Why this order:

1. **`WidgetsFlutterBinding.ensureInitialized()` first** — required before any async Flutter API (incl. `SharedPreferences.getInstance()`).
2. **`dotenv.load()` before DI** — `ApiClient`'s base URL comes from `ApiEndpoints.BASE_URL` which reads `dotenv.env['BASE_URL']`.
3. **`initDependencies()` before `runApp`** — `DeepLinkService` and `LocalStorage` must be registered before the app starts.
4. **No route decision in `main.dart`** — `router()` always sets `initialLocation: RoutePaths.AUTHENTICATION`; `_guard` immediately redirects a signed-in user to `HOME`. This intentional simplification removes the redundant `initDest` threading that duplicated guard logic. A signed user may briefly hit the async guard redirect on cold start.

After `runApp`, `App` initialises `DeepLinkService.init()` in its `initState` — handles both cold-start and warm-start links via `uriLinkStream`.

## Hands-off boundary

These files are foundation that every module depends on. Don't edit without explicit user approval:

```
# Networking foundation
lib/core/network/api_client.dart
lib/core/network/api_result.dart
lib/core/network/exceptions.dart
lib/core/network/error_handler.dart
lib/core/network/api_methods.dart
lib/core/network/protocol_type.dart
lib/core/network/interceptors/auth_interceptor.dart

# Storage
lib/core/local/local_storage.dart

# Base usecase contract
lib/core/usecase/usecase.dart

# Composition root
lib/core/di/service_locator.dart                       # registration ORDER is delicate; add `_init<Module>()` only with approval
lib/app/router/app_router.dart                         # _guard logic is hands-off — route additions ARE fine

# Project-wide
analysis_options.yaml
pubspec.yaml                                           # only when adding deps explicitly requested by the user
```

When a task seems to require touching a hands-off file:

1. **Stop.** Don't edit silently.
2. **Surface the need.** Explain WHAT and WHY in plain language, with 2-3 alternatives:
   - Extend via a new class (e.g. an extra interceptor in `core/network/interceptors/`).
   - Compose a sibling file (e.g. a new `core/network/<something>.dart`).
   - Add a utility elsewhere (e.g. `core/helpers/foo.dart`).
3. **Wait for approval.** Only after the user explicitly says yes.

NOT hands-off (edit freely):

- `lib/core/network/api_endpoints.dart` — add path constants any time
- `lib/core/network/interceptors/logging_interceptor.dart` — formatting tweaks ok
- `lib/app/router/app_router.dart` — adding `GoRoute` blocks for new modules is normal
- `lib/app/router/route_names.dart` — add new `RoutePaths.*` / `RouteNames.*` constants
- `lib/core/constants/*` — add colors, spacing, radius, typography tokens
- `lib/core/helpers/*` — add extensions, validators
- `lib/core/widgets/*` — add cross-module widgets (NOT module-specific)
- `lib/core/deeplink/deeplink_service.dart` — adjust routing logic per project
- `lib/modules/*` — anywhere within a module folder
- `lib/main.dart`, `lib/app/app.dart` — adjust bootstrap order ONLY if reason is documented in the PR

## Per-module barrel

Each module ships a single barrel at the module root, named after the module. Re-exports the public surface (NOT generated `.freezed.dart` / `.g.dart` files — those are implementation detail consumed only via the model that imports them).

Example from `lib/modules/auth/auth.dart`:

```dart
// [DOMAIN]
export 'domain/entities/user_entity.dart';
export 'domain/repository/auth_repository.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/resend_usecase.dart';
export 'domain/usecases/verify_usecase.dart';
export 'domain/usecases/magic_link_usecase.dart';

// [DATA]
export 'data/models/user_model.dart';
export 'data/models/credentials_model.dart';
export 'data/services/auth_service.dart';
export 'data/repository/auth_repository_impl.dart';

// [PRESENTATION]
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/bloc/auth_event.dart';
export 'presentation/bloc/auth_state.dart';
export 'presentation/widgets/auth_textfield.dart';
export 'presentation/pages/authentication_page.dart';
export 'presentation/pages/register_page.dart';
export 'presentation/pages/login_page.dart';
export 'presentation/pages/verify_email_page.dart';
export 'presentation/pages/verification_success_page.dart';
export 'presentation/pages/homepage.dart';
```

Composition root and cross-module consumers import as one unit:
```dart
import 'package:eatinpal/modules/auth/auth.dart';
```

Internal-to-module imports (one file in `data/services/` reaching a file in `data/models/`) still use direct `package:` paths — don't import the module's own barrel from inside the module (creates a circular re-export risk).

## Common pitfalls

- **Cross-module import** — `modules/food/.../food_page.dart` imports `modules/auth/.../user_model.dart`. Fix: if the type is genuinely cross-module, lift `UserEntity` to a shared `core/` location (rare — usually the domain entity stays in its owning module and the consumer talks to the owning module via a usecase).
- **`domain` importing `data`** — entity importing freezed model, or repository interface importing the impl. Fix: invert; `data` always depends on `domain`, never the other way.
- **Core depending on a module** — `core/helpers/jwt.dart` imports something from `modules/auth/`. Fix: if the helper needs auth-specific data, it doesn't belong in `core/`; move into `modules/auth/`.
- **Module reaching another module's BLoC** — `FoodPage` calls `BlocProvider.of<AuthBloc>(context)` from outside an `AuthBloc` provider scope. With `registerFactory`, each `BlocProvider` gets a fresh `AuthBloc` — reading auth state across pages requires a shared `AuthRepository` (singleton) or a session service.
- **Silently editing a hands-off file** — surfaces the issue late and forces re-review of every consumer. Surface first, edit after approval.
- **Forgetting to regenerate** — after editing a freezed source, the `*.freezed.dart` / `*.g.dart` files are stale. `fvm dart run build_runner build --delete-conflicting-outputs` and commit.

## See also

- `02-conventions.md` — naming, function length, imports, comments, fpdart Either
- `03-state-routing.md` — `flutter_bloc` patterns, `get_it` registration, `go_router`, dialogs / sheets / snackbars
- `04-networking.md` — `ApiClient` + `ApiResult<T>` + interceptors + envelope
- `05-clean-architecture.md` — Service ↔ Repository ↔ UseCase ↔ BLoC contracts
- `06-modules.md` — end-to-end feature build flow
- `CLAUDE.md` § Critical rules — rules `modular-structure`, `hands-off`, `import-rules`

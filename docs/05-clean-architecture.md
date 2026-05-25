# Clean Architecture (Service ↔ Repository ↔ UseCase ↔ BLoC)

The contract for the four layers inside every module. Replaces base's `05-base-classes.md` — EatinPal uses Clean Architecture per module instead of base controllers / views.

## The pipeline

```
presentation/
  Page                                                # UI (BlocProvider + BlocConsumer)
  Bloc<Event, State>          ← extends Bloc          # orchestrator; calls usecases; emits states
       ↓ depends on
domain/
  UseCase<T, Params>          ← extends UseCase       # one method: call(params) → Either<AppException, T>
       ↓ depends on
  Repository                  ← abstract              # plain Dart interface; defines what the domain needs
       ↑ implements
data/
  RepositoryImpl              ← implements            # composes Service(s) + LocalStorage; converts ApiResult → T
       ↓ depends on
  Service                     ← non-abstract class    # calls ApiClient; returns Either<AppException, ApiResult<T>>
       ↓ depends on
core/
  ApiClient                                           # Dio wrapper
```

Each arrow is a real Dart `import`. Reversing any arrow violates the architecture.

## Domain layer (innermost — no external deps)

### Entities

`lib/modules/<name>/domain/entities/<name>_entity.dart` — plain Dart classes. NO freezed, NO json_serializable.

Real example:

```dart
// lib/modules/auth/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? avatarURL;
  final bool emailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarURL,
    required this.emailVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

Optional: extend `Equatable` if the entity is ever compared by value or used as a `BlocBuilder` key. Default — no Equatable unless needed.

### Repository interface

`lib/modules/<name>/domain/repository/<name>_repository.dart` — abstract class. Methods return `Future<Either<AppException, T>>`.

```dart
// lib/modules/auth/domain/repository/auth_repository.dart
abstract class AuthRepository {
  Future<Either<AppException, String>> login({
    required String email,
    required String password,
  });

  Future<Either<AppException, String>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<AppException, String>> resendVerification({required String email});
  Future<Either<AppException, String>> verify({required String token});
  Future<Either<AppException, String>> verifiedLogin({required String token});
}
```

The interface returns DOMAIN types — `UserEntity`, `FoodEntity`, primitives like `String`/`bool`. NEVER `UserModel` / `ApiResult<T>` / `Map<String, dynamic>` — those are data-layer concerns.

In the auth module, several methods return `Right(String)` — the envelope's `message` field, which the BLoC turns into a snackbar / page transition trigger. Tokens persist as a side-effect inside the repository impl.

### UseCase

`lib/modules/<name>/domain/usecases/<verb>_<noun>_usecase.dart`. Extends `UseCase<T, Params>` or `UseCaseNoParams<T>`:

```dart
// lib/core/usecase/usecase.dart
abstract class UseCase<T, Params> {
  Future<Either<AppException, T>> call(Params params);
}

abstract class UseCaseNoParams<T> {
  Future<Either<AppException, T>> call();
}

class NoParams {
  const NoParams();
}
```

`NoParams` is a placeholder when a usecase logically takes no input but you still want to use `UseCase<T, NoParams>`. Prefer `UseCaseNoParams<T>` — it's cleaner.

#### Single-field params — pass the primitive directly

```dart
// ✅
class ResendVerificationUseCase extends UseCase<String, String> {
  final AuthRepository _repository;
  ResendVerificationUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(String email) {
    return _repository.resendVerification(email: email);
  }
}

// Call site
final result = await sl<ResendVerificationUseCase>()(email);
```

The signature `UseCase<String, String>` reads as "returns `String`, takes `String`" — the second param is the primitive, no wrapper. From `auth_bloc.dart`:

```dart
final result = await _resendVerification(event.email);
```

#### Multi-field params — wrap in a class

```dart
class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

class LoginUseCase extends UseCase<String, LoginParams> {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(LoginParams params) {
    return _repository.login(email: params.email, password: params.password);
  }
}

// Call site
final result = await sl<LoginUseCase>()(
  LoginParams(email: event.email, password: event.password),
);
```

Naming: `<Verb><Noun>Params` (PascalCase). All fields `final`, `const` constructor where possible.

#### No-params usecase

```dart
class GetProfileUseCase extends UseCaseNoParams<UserEntity> {
  final UserRepository _repository;
  GetProfileUseCase(this._repository);

  @override
  Future<Either<AppException, UserEntity>> call() {
    return _repository.getProfile();
  }
}

// Call site
final result = await sl<GetProfileUseCase>()();
```

## Data layer (depends on `domain`, never the other way)

### Models — extend / implement entity

`lib/modules/<name>/data/models/<name>_model.dart`. Freezed + `json_serializable`, `implements <Name>Entity` (NOT `extends` — freezed already controls the class shape).

```dart
// lib/modules/auth/data/models/user_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:eatinpal/modules/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel implements UserEntity {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    @JsonKey(name: 'avatar_url') required String? avatarURL,
    @JsonKey(name: 'email_verified') required bool emailVerified,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

Patterns:

- `abstract class FooModel with _$FooModel implements FooEntity` — `abstract` is required by freezed v3+.
- `@JsonKey(name: 'snake_case_name')` — backend's `snake_case` → Dart's `camelCase`.
- `fromJson` factory delegates to generated `_$FooModelFromJson`.
- `toJson` is generated automatically (`json_serializable`).
- Generated files (`*.freezed.dart`, `*.g.dart`) ARE committed.

After editing, regenerate:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Or in watch mode while iterating:

```bash
fvm dart run build_runner watch --delete-conflicting-outputs
```

### Service

`lib/modules/<name>/data/services/<name>_service.dart`. Calls `ApiClient`, returns `Future<Either<AppException, ApiResult<T>>>`.

See `04-networking.md` § Service pattern for the full pattern.

Key points:

- One class per module's service. If the module has many endpoints, group them in this single class — no need to split unless it exceeds ~300 lines.
- Constructor takes `ApiClient` (positional, private) + maybe `LocalStorage`. `const` where possible.
- Each method maps 1:1 to an endpoint.
- Tuple payloads use Dart 3.0+ records (`typedef LoginResponse = ({UserModel user, TokensModel tokens});`).

### Repository implementation

`lib/modules/<name>/data/repository/<name>_repository_impl.dart`. `implements <Name>Repository`. Composes service(s) + (optionally) `LocalStorage`.

```dart
// lib/modules/auth/data/repository/auth_repository_impl.dart
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

  @override
  Future<Either<AppException, String>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _service.register(email: email, password: password, name: name);
    return result.fold(
      (left) => Left(left),
      (right) => Right(right.message),
    );
  }

  // ...
}
```

Patterns:

- Constructor takes services + storage positional.
- `.fold((left) => Left(left), (right) => Right(...))` to convert `Either<AppException, ApiResult<T>>` → `Either<AppException, U>` where `U` is the domain type the repository interface promised.
- Side-effects (persisting tokens, clearing cache) happen inside the `right` branch.
- When unwrapping just the `data`: `Right(right.data)`.
- When unwrapping just the `message` (write op): `Right(right.message)`.

## Presentation layer — BLoC

See `03-state-routing.md` for the full BLoC reference. Summary:

- `<Name>Bloc extends Bloc<<Name>Event, <Name>State>` — depends on usecases via constructor injection.
- Events and states extend `Equatable` (NEVER freezed).
- `registerFactory` for the BLoC in `service_locator.dart` — new instance per page.
- Pages use `BlocProvider(create: (_) => sl<<Name>Bloc>(), child: ...)`.
- Side-effects (snackbar, navigation) via `BlocListener`, UI rebuilds via `BlocBuilder`.

Real BLoC handler that exercises the whole pipeline:

```dart
Future<void> _onLogin(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
  emit(const AuthLoading());

  final result = await _login(            // UseCase.call
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
```

Page side-effects:

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
    } else if (state is AuthRequiresVerification) {
      AppSnackbar.warning(context, state.message);
      context.push(RoutePaths.VERIFY_EMAIL, extra: VerifyEmailArgs(email: ...));
    } else if (state is AuthAuthenticated) {
      AppSnackbar.success(context, state.message);
      context.go(RoutePaths.HOME);
    }
  },
  child: ...,
)
```

## Dependency graph for the `auth` module

```
AuthenticationPage / LoginPage / RegisterPage / VerifyEmailPage / VerificationSuccessPage / HomePage
   │   (BlocProvider creates →)
   ▼
AuthBloc            extends Bloc<AuthEvent, AuthState>     [registerFactory]
   │
   ├─→ LoginUseCase                  extends UseCase<String, LoginParams>      [lazySingleton]
   ├─→ RegisterUseCase                extends UseCase<String, RegisterParams>  [lazySingleton]
   ├─→ ResendVerificationUseCase      extends UseCase<String, String>          [lazySingleton]
   ├─→ VerifyUseCase                  extends UseCase<String, String>          [lazySingleton]
   └─→ VerifiedLoginUseCase           extends UseCase<String, String>          [lazySingleton]
            │
            ▼
        AuthRepository (abstract)
            │
            ▼
        AuthRepositoryImpl                                                      [lazySingleton]
            │
            ├─→ AuthService                                                     [lazySingleton]
            │        │
            │        └─→ ApiClient                                              [lazySingleton]
            │                  │
            │                  ├─→ Dio                                          [lazySingleton]
            │                  ├─→ AuthInterceptor (constructed inline)
            │                  └─→ LoggingInterceptor (constructed inline)
            │
            └─→ LocalStorage                                                    [singleton, async init]
```

Every arrow is a constructor parameter. Every node lives in `get_it`.

## Why each layer

| Layer | Why |
|---|---|
| **Entity** | Pure domain type. The rest of the app speaks in entities, not in transport-layer JSON shapes. Future change of backend / serialization doesn't touch presentation. |
| **Repository interface** | Domain-side contract. UseCases depend on this — they're swappable in tests with a stub repo. |
| **UseCase** | Encapsulates ONE business action. Trivial to test; readable from BLoC. Future business rule (e.g. throttle, audit log) lands here, not in BLoC. |
| **Service** | Endpoint mapper. One method = one HTTP call. Doesn't unwrap envelopes. |
| **Repository impl** | Composes services + storage. Converts data-layer types to domain types. Side-effects (persist tokens). |
| **Bloc** | Orchestrates usecases, manages reactive state. Doesn't know about Dio or `ApiResult` — only about usecases and domain types. |

## Common pitfalls

- **Repository returns `Either<AppException, ApiResult<T>>`** — caller (UseCase / Bloc) ends up unwrapping `right.data`, defeating the layer. The repository's job is to unwrap.
- **Entity holds `Map<String, dynamic>` or freezed annotations** — entities are pure Dart, no codegen.
- **Service returns `T` directly (throws on error)** — `ApiClient` already catches `DioException`. Services return `Either<AppException, ApiResult<T>>`.
- **UseCase calls another UseCase** — discouraged. UseCases are domain primitives. Combining business actions belongs in a higher-level usecase, or in the BLoC orchestrating two UseCases sequentially (see `AuthBloc._onVerifyFromLink`).
- **Forgetting to register a new layer in `service_locator.dart`** — `sl<NewBloc>()` throws "Type not registered". Always wire the full chain.
- **Wrong registration mode** — registering a BLoC as `lazySingleton` means subsequent page entries share state. BLoCs are factory.
- **Models extend (not implement) the entity** — works only if the entity isn't `abstract`; freezed prefers `implements`. Standardise on `implements`.
- **Repository methods named after HTTP verbs (`postLogin`, `getProfile`)** — name them after the business action (`login`, `getProfile` is okay, `register` is okay; `postLogin` is not).

## See also

- `01-architecture.md` — folder layout, layering rules
- `02-conventions.md` — naming, fpdart `Either`, code generators
- `03-state-routing.md` — BLoC patterns
- `04-networking.md` — service-layer detail, `ApiResult<T>`
- `06-modules.md` — feature build flow (assembles all layers)
- `CLAUDE.md` § Critical rules — rules 3 (models extend entity), 4 (BLoC never freezed), 5 (modular structure), 7 (fpdart Either)
- `lib/core/usecase/usecase.dart` — base classes
- `lib/modules/auth/` — full reference implementation across all four layers

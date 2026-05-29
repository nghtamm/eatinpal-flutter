---
name: modular-structure
description: Every feature lives at `lib/modules/<name>/` with Clean Architecture layers (`data/`, `domain/`, `presentation/`). Mandatory per-module barrel at `<name>.dart`. No barrels inside sub-folders. Modules don't import each other.
---

# Rule: Modular structure

## Constraint

Every feature is a module. Each module is a folder under `lib/modules/<name>/` with three Clean-Architecture layers and one barrel file:

```
lib/modules/<name>/
├── <name>.dart                  # MANDATORY per-module barrel — re-exports the public surface
├── data/
│   ├── models/<name>_model.dart        # freezed + json_serializable, extends entity
│   ├── repository/<name>_repository_impl.dart
│   └── services/<name>_service.dart    # calls _client.request(...)
├── domain/
│   ├── entities/<name>_entity.dart
│   ├── repository/<name>_repository.dart   # abstract
│   └── usecases/<verb>_<name>_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── <name>_bloc.dart
    │   ├── <name>_event.dart            # Equatable, NEVER freezed
    │   └── <name>_state.dart            # Equatable, NEVER freezed
    ├── pages/<name>_page.dart
    └── widgets/                          # OPTIONAL — module-private widgets
```

**One barrel per module, at the module root.** Named after the module (`auth/auth.dart`, `food/food.dart`). Re-exports the public surface (bloc, pages, entities/usecases that other modules may consume — though ideally other modules consume nothing). No barrels inside sub-folders (no `data/data.dart`, no `presentation/presentation.dart`).

**No top-level `lib/modules/modules.dart`** — the composition root (`lib/app/router/app_router.dart`, `lib/main.dart`) imports each module's barrel directly.

**Modules MUST NOT import each other.** Cross-module sharing goes through `lib/core/`. The composition root may import any module's barrel.

## Layer flow

```
Page / Widget
    ↓
BLoC  ─── adds Event → emits State
    ↓
UseCase  ─── returns Future<Either<AppException, T>>
    ↓
Repository (abstract) ←──── RepositoryImpl
                                ↓
                            Service ─── calls _client.request(...)
                                ↓
                           ApiClient ─── returns Either<AppException, ApiResult<T>>
```

Entities live in `domain/`. Models in `data/models/` EXTEND or IMPLEMENT entities and add `fromJson`/`toJson` via `freezed` + `json_serializable`.

## Why

- Each feature can be reasoned about, edited, and tested in isolation.
- Clear ownership — moving or removing a feature deletes one folder.
- Per-module barrel lets the composition root import the module with one line.
- Clean Arch layering prevents UI from reaching directly into networking — every call goes through usecase → repository → service.

## Per-module barrel

Each module's `<name>.dart` re-exports the consumer-facing surface. Example:

```dart
// lib/modules/auth/auth.dart
export 'data/models/credentials_model.dart';
export 'data/models/user_model.dart';
export 'data/repository/auth_repository_impl.dart';
export 'data/services/auth_service.dart';
export 'domain/entities/credentials_entity.dart';
export 'domain/entities/user_entity.dart';
export 'domain/repository/auth_repository.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/resend_usecase.dart';
export 'domain/usecases/magic_link_usecase.dart';
export 'domain/usecases/verify_usecase.dart';
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/bloc/auth_event.dart';
export 'presentation/bloc/auth_state.dart';
export 'presentation/pages/authentication_page.dart';
export 'presentation/pages/login_page.dart';
export 'presentation/pages/register_page.dart';
export 'presentation/pages/verification_success_page.dart';
export 'presentation/pages/verify_email_page.dart';
```

Internal-to-module imports use direct relative paths — don't import the module's own barrel from inside the module.

## Examples

### ✅ Correct — composition root imports module barrel

```dart
// lib/app/router/app_router.dart
import 'package:eatinpal/modules/auth/auth.dart';

GoRoute(
  path: RoutePaths.LOGIN,
  name: RouteNames.LOGIN,
  builder: (context, state) => const LoginPage(),
),
```

### ✅ Correct — register module deps in service_locator

```dart
// lib/core/di/service_locator.dart
import 'package:eatinpal/modules/auth/auth.dart';

void _registerAuthModule() {
  di
    ..registerLazySingleton<AuthService>(() => AuthService(di()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(di(), di()),
    )
    ..registerLazySingleton(() => LoginUseCase(di()))
    ..registerLazySingleton(() => RegisterUseCase(di()))
    ..registerFactory(() => AuthBloc(
          register: di(),
          login: di(),
          resend: di(),
          verify: di(),
          magicLink: di(),
        ));
}
```

### ❌ Incorrect — direct cross-module import

```dart
// In lib/modules/profile/presentation/pages/profile_page.dart
import 'package:eatinpal/modules/auth/presentation/bloc/auth_bloc.dart';   // ❌
```

If profile genuinely needs auth state (e.g., current user), lift it to `core/` (e.g., a `SessionService` in `core/` that both modules can consume).

### ❌ Incorrect — barrel inside a sub-folder

```dart
// ❌ lib/modules/auth/data/data.dart
export 'models/user_model.dart';
export 'repository/auth_repository_impl.dart';
// ...
```

Sub-folder barrels create indirection without benefit. Only the module-root `<name>.dart` barrel exists.

## When you need to break the rule

If two modules genuinely share state or types and you can't factor them into `core/`, surface it. Example:

> "The `food` module needs to read the current user from `auth`. Options:
> 1. Lift a `SessionService` to `core/` (auth writes to it, food reads from it).
> 2. Cross-module import (forbidden).
>
> Recommend (1). OK?"

Don't silently add a cross-module import.

## What goes in `core/`

- Tokens (`AppColors`, `AppSpacing`, `AppTypography`, `AppTheme`) — `core/constants/`
- Cross-module shared widgets (`AppButton`, `AppSnackbar`, `BasicAppBar`, `LoadingOverlay`) — `core/widgets/`
- Network plumbing (`ApiClient`, `ApiResult`, `AppException`, interceptors) — `core/network/`
- Persistence abstraction (`LocalStorage`) — `core/local/`
- Helpers (`Validators`, `JwtUtils`, extensions) — `core/helpers/`
- DI composition — `core/di/service_locator.dart`
- Base usecase — `core/usecase/usecase.dart`
- Deep-link service — `core/deeplink/deeplink_service.dart`

## What does NOT go in `core/`

- Module-specific widgets (a "login form" used only on the login page) → `lib/modules/auth/presentation/widgets/`
- Module-specific entities/models → stays in the module's `domain/` or `data/`

## See also

- `docs/06-modules.md` — module pattern narrative
- `docs/11-module-scaffold.md` — step-by-step playbook for adding a new module
- `docs/01-architecture.md` § Cross-module rule
- `.claude/rules/state-management.md` — BLoC + DI registration pattern

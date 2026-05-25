# Overview

Entry point into the deep reference for the EatinPal codebase. Introduces what the project is, the tech stack, how the AI harness is organised, and how to navigate the rest of the docs.

If you are an AI agent following a rule or guide — those layers are summary-level by design. Anything labelled `See also: docs/...` lives here in full detail.

## What this codebase is

EatinPal is a Flutter mobile app (Android + iOS only) for tracking daily calories and nutrition, similar to MyFitnessPal. The backend is NestJS with JWT auth (silent refresh-token rotation). It ships with:

- **Clean Architecture per module** under `lib/modules/<name>/` with mandatory `data/`, `domain/`, `presentation/` layers.
- **`flutter_bloc`** for state — events and states are regular classes with `Equatable`, NEVER freezed.
- **`get_it`** for dependency injection — single instance `sl` registered in `lib/core/di/service_locator.dart`.
- **`go_router`** for navigation, with auth gating via a `redirect` guard reading `LocalStorage.signed`.
- **`Dio`** with a custom `ApiClient` wrapper, two interceptors (`AuthInterceptor` + `LoggingInterceptor`), envelope auto-extraction, silent refresh-token rotation on 401.
- **`fpdart` `Either<AppException, T>`** as the result contract — repositories and usecases return it; services return `Either<AppException, ApiResult<T>>` (envelope-wrapped).
- **`freezed` + `json_serializable`** for data models — models extend / implement the matching domain entity. Generated files are committed.
- **Token-based design system** under `lib/core/constants/` — `AppColors`, `AppSpacing` (with `AppPadding`, `AppRadius` siblings), `AppTypography`, `AppFonts`, `AppTheme`. Never inline raw design literals.
- **Deep linking** via `app_links` — `DeepLinkService` handles warm-start streams; cold-start is resolved in `main.dart` before `runApp`.
- **`flutter_dotenv`** — `.env` loaded at boot, used by `ApiEndpoints.BASE_URL`.

## Tech stack at a glance

| Concern | Package |
|---|---|
| State | `flutter_bloc` (with `equatable`) |
| DI | `get_it` |
| Routing | `go_router` |
| HTTP | `dio` |
| Functional / error handling | `fpdart` (`Either`) |
| Models | `freezed`, `json_annotation` (+ `freezed_annotation`) |
| Local KV | `shared_preferences` |
| Secure KV | `flutter_secure_storage` |
| Env | `flutter_dotenv` |
| Deep linking | `app_links` |

Dev deps: `flutter_test`, `flutter_lints`, `build_runner`, `freezed`, `json_serializable`.

Dart SDK `^3.11.4`, Flutter 3.41+. **All Flutter / Dart CLI calls go through FVM** — `fvm flutter`, `fvm dart`. Never bare `flutter` / `dart`.

## Architecture at a glance

```
lib/
├── main.dart                       # bootstrap — WidgetsFlutterBinding, dotenv, DI, initial deep-link route, runApp
├── app/
│   ├── app.dart                    # AppRoot — MaterialApp.router + AppTheme.light + DeepLinkService lifecycle
│   └── router/
│       ├── app_router.dart         # composition root for routes + auth guard (_guard)
│       └── route_names.dart        # RoutePaths (UPPER_SNAKE_CASE) + RouteNames (UPPER_SNAKE_CASE)
├── core/                           # shared, NO barrel — import individual files
│   ├── constants/                  # AppColors, AppSpacing / AppPadding / AppRadius, AppTypography, AppFonts, AppTheme
│   ├── deeplink/                   # DeepLinkService — warm-start stream + cold-start helper
│   ├── di/                         # service_locator.dart — `sl` instance + `initDependencies()` + `_initCore` / `_initAuth`
│   ├── helpers/                    # extensions, validators, jwt
│   ├── local/                      # LocalStorage interface + LocalStorageImpl (secure + prefs)
│   ├── network/                    # ApiClient, ApiResult, ApiEndpoints, exceptions, ErrorHandler, ApiMethods, ProtocolType
│   │   └── interceptors/           # auth_interceptor.dart (silent refresh), logging_interceptor.dart
│   ├── usecase/                    # UseCase<T, Params> / UseCaseNoParams<T> / NoParams
│   └── widgets/                    # AppButton, AppSnackbar, BasicAppBar, LoadingOverlay (cross-module)
└── modules/                        # one folder per feature; NO top-level barrel
    └── auth/                       # sample module — full clean architecture
        ├── auth.dart               # MANDATORY per-module barrel
        ├── data/
        │   ├── models/             # UserModel, TokensModel (freezed, extend entity)
        │   ├── services/           # AuthService — calls ApiClient
        │   └── repository/         # AuthRepositoryImpl — wraps services, persists tokens
        ├── domain/
        │   ├── entities/           # UserEntity, TokensEntity
        │   ├── repository/         # AuthRepository (abstract)
        │   └── usecases/           # LoginUseCase, RegisterUseCase, VerifyUseCase, ...
        └── presentation/
            ├── bloc/               # AuthBloc + AuthEvent + AuthState (Equatable, multi-class)
            ├── pages/              # AuthenticationPage, LoginPage, RegisterPage, ...
            └── widgets/            # AuthTextField, PasswordStrength (module-scoped)
```

Each module ships a single per-module barrel at `lib/modules/<name>/<name>.dart` re-exporting the public surface (entities, repository interface, usecases, BLoC + events + states, public widgets, pages). The composition root and other consumers import the module as one unit: `import 'package:eatinpal/modules/auth/auth.dart';`. No barrels inside sub-folders. There is NO top-level `lib/modules/modules.dart`.

Full layering rules, hands-off boundary, and bootstrap sequence are in `01-architecture.md`.

## AI harness at a glance

The harness lives at the repository root:

```
CLAUDE.md                            # always-loaded master — critical rules, working principles, indexes
docs/<NN>-<name>.md                  # deep reference layer — loaded on demand when CLAUDE.md links in
.claude/                             # Claude Code tool-specific (optional rules / agents — currently empty by design)
```

`CLAUDE.md` is the load-bearing summary. `docs/` is the depth layer — expanded narratives, code samples adapted from the actual EatinPal source, decision matrices.

## How to navigate this `docs/` folder

These docs are the **deepest reference layer**. They are loaded on demand — not pulled into prompt context automatically. `CLAUDE.md` links here whenever extra depth is useful.

**Topical map:**

| Topic | Doc |
|---|---|
| Folder layout, layering, composition root, bootstrap, hands-off boundary | `01-architecture.md` |
| Naming, function length, imports, comments, code generators (freezed/json_serializable), shared defs, trailing commas, fpdart Either | `02-conventions.md` |
| flutter_bloc patterns (Style A/B), `get_it` registration, `go_router`, dialogs / sheets / snackbars (`AppSnackbar`), deep links | `03-state-routing.md` |
| `ApiClient` + `ApiResult<T>` + `Either<AppException, T>` + interceptors + envelope + uploads + refresh-token rotation | `04-networking.md` |
| Clean Architecture per module — Service ↔ Repository ↔ UseCase ↔ BLoC contracts, single-field usecase pattern, models extending entities | `05-clean-architecture.md` |
| Module anatomy + end-to-end feature build flow + form handling | `06-modules.md` |
| Design tokens (`AppColors`, `AppSpacing`/`AppPadding`/`AppRadius`, `AppTypography`), shared widgets (`AppButton`, `AppSnackbar`, `BasicAppBar`, `LoadingOverlay`), state matrix, a11y, responsive | `07-theming-ui.md` |
| dotenv, secure storage, deep links (`app_links`), permissions, offline UX, dependencies policy | `08-platform.md` |
| Mobile performance checklist + decisions (BLoC rebuild scoping, `const`, `ListView.builder`, image sizing, `RepaintBoundary`) | `09-performance.md` |
| Working principles in depth, hands-off protocol, harness sync rule, docs depth layer | `10-ai-harness.md` |
| Adding a new module from scratch — copy-paste playbook | `11-module-scaffold.md` |

## How a human reader should approach this codebase

1. Read this overview.
2. Skim `01-architecture.md` to get the layering mental model.
3. Skim `06-modules.md` to see how a feature is built end-to-end.
4. Read `02-conventions.md` once — it's the load-bearing style spec.
5. Reach for the others when you touch their area.

## What is intentionally NOT in this codebase

These are decisions deferred per-project, NOT defaults shipped:

- CI/CD pipelines
- Push notifications (Firebase Cloud Messaging not wired)
- Analytics / crash reporting (no Firebase Core yet)
- Multi-flavor builds (`dev` / `stg` / `prod` not configured — single env via `.env`)
- Localisation / i18n (`flutter_localizations` + ARB not wired)
- Onboarding flow
- Production-ready forms beyond the auth sample

When you add any of these, update the relevant doc per working principle 7 (harness sync).

## See also

- `01-architecture.md` — layering, composition root, bootstrap order
- `10-ai-harness.md` — working principles, sync protocol, depth layer policy
- `CLAUDE.md` — critical rules + working principles + indexes (always loaded)

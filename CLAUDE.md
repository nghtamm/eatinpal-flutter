# EatinPal - Flutter Calorie & Nutrition Tracker

Mobile app (Android + iOS only) for tracking daily calories and nutrition, similar to MyFitnessPal. Backend is NestJS with JWT auth.

## Tech stack at a glance

| Concern | Package |
|---|---|
| State management | `flutter_bloc` (events/states with `Equatable`, NEVER freezed) |
| DI | `get_it` (instance `di` in `lib/core/di/service_locator.dart`) |
| HTTP | `dio` + custom `ApiClient` wrapper (`lib/core/network/api_client.dart`) |
| Routing | `go_router` (routes in `lib/app/router/`) |
| Functional / error handling | `fpdart` — `Either<AppException, T>` |
| Models | `freezed` + `json_serializable` (models extend their entity) |
| Secure storage | `flutter_secure_storage` (tokens) |
| Local prefs | `shared_preferences` |
| Env | `flutter_dotenv` |
| Deep linking | `app_links` |

Dart SDK `^3.11.4`, Flutter 3.41+ via **FVM**. Always use `fvm flutter` / `fvm dart` — never bare `flutter` / `dart`.

## Architecture at a glance

Clean Architecture per module with 3 layers (`data` / `domain` / `presentation`):

```
lib/
├── main.dart                       # bootstrap entry — Widgets bind → dotenv → DI → initial route → runApp
├── app/
│   ├── app.dart                    # MaterialApp.router + theme + DeepLinkService lifecycle
│   └── router/
│       ├── app_router.dart         # composition root for routes + guard
│       └── route_names.dart        # RoutePaths + RouteNames
├── core/                           # shared, NO barrel export — import individual files
│   ├── constants/                  # AppColors, AppSpacing/AppPadding/AppRadius, AppTypography, AppTheme, AppFonts
│   ├── di/                         # service_locator.dart (GetIt instance `di`)
│   ├── deeplink/                   # DeepLinkService (warm + cold-start)
│   ├── helpers/                    # extensions, validators, jwt
│   ├── local/                      # LocalStorage interface + LocalStorageImpl
│   ├── network/                    # ApiClient, ApiResult, exceptions, ErrorHandler, ApiEndpoints, interceptors/
│   ├── usecase/                    # UseCase<T, Params> / UseCaseNoParams<T> / NoParams
│   └── widgets/                    # AppButton, AppSnackbar, BasicAppBar, LoadingOverlay (+ AppCircularProgress)
└── modules/
    └── <module>/
        ├── <module>.dart           # MANDATORY barrel export
        ├── data/                   # models (freezed, extend entity), services, repositories (impl)
        ├── domain/                 # entities, repository interfaces, usecases
        └── presentation/           # bloc/event/state, pages, widgets (module-scoped)
```

Layer flow: Services → ApiClient; Repositories → Services; UseCases → Repositories; BLoC → UseCases.

Sample module: `lib/modules/auth/` (full clean-arch implementation with login, register, magic-link verification).

Full layering rules, hands-off boundary, and bootstrap sequence: `docs/01-architecture.md`.

## Critical rules — apply ALWAYS

> Full text of every rule is in the linked `docs/`. The summary below is the load-bearing minimum.

1. **Naming.** Files `snake_case`, classes `PascalCase`, methods/vars `camelCase` (short — 1 word preferred, 2-3 max), constants & enum values `UPPER_SNAKE_CASE`, private members prefixed `_`. Private widget-builder helpers in pages drop the `_build` prefix — `_banner()` not `_buildBanner()` (does not apply to framework `build(BuildContext)`). (`docs/02-conventions.md`)
2. **Function length.** Target ~100 lines, soft upper bound ~300. Refactor by extracting private helpers, sub-widgets, or utilities in `core/helpers/`. (`docs/02-conventions.md`)
3. **Models — freezed + json_serializable, extending entity.** Data models live in `data/models/`, extend / implement the matching entity in `domain/entities/`. Generated `*.freezed.dart` / `*.g.dart` committed to git. Re-run `fvm dart run build_runner build --delete-conflicting-outputs` after editing freezed sources. (`docs/02-conventions.md`)
4. **BLoC — never freezed.** Events and states are regular classes with `Equatable`, override `props`. Two styles: A (multi-class, divergent shapes — default) or B (single-class with enum status — shared fields). (`docs/03-state-routing.md`)
5. **Modular structure.** Every feature at `lib/modules/<name>/` with `data/`, `domain/`, `presentation/`. Mandatory per-module barrel `<name>.dart` re-exporting public surface. No barrels inside sub-folders. No top-level `modules.dart`. Modules MUST NOT import each other — lift to `core/` instead. (`docs/06-modules.md`)
6. **Networking.** All API calls go through services that call their injected `ApiClient` (e.g. `_client.request(endpoint: ...)`) and return `Future<Either<AppException, ApiResult<T>>>`. Repositories unwrap and return `Either<AppException, T>`. `RestMethod.GET/POST/PUT/PATCH/DELETE` (enum values are `UPPER_SNAKE_CASE`). Envelope auto-extracted by `ApiClient._unwrap`. (`docs/04-networking.md`)
7. **fpdart Either.** Unwrap with `.fold((left) => ..., (right) => ...)` — always name params `left` / `right`, NOT domain names. Avoid `switch (result) { case Left ... case Right }` pattern. For single-field usecase params, skip the wrapper class — pass the primitive directly. (`docs/02-conventions.md`)
8. **State + routing.** `flutter_bloc` for state, `get_it` for DI, `go_router` for navigation. NO Provider, Riverpod, MobX, Redux, GetX. Resolve dependencies via `di<T>()` — registered in `core/di/service_locator.dart`. (`docs/03-state-routing.md`)
9. **Hands-off files.** Foundation files in `lib/core/network/`, `lib/core/local/`, `lib/core/usecase/`, `lib/core/di/service_locator.dart`, `lib/app/router/app_router.dart` (guard), `lib/core/network/interceptors/auth_interceptor.dart` require explicit user approval to modify. Extend with new classes or compose new sibling files instead. Full list in `docs/01-architecture.md` § Hands-off boundary. (`docs/01-architecture.md`)
10. **Trailing commas.** Multi-line argument / parameter / collection literals end with a trailing comma. Single-line constructs do not. Fix with `fvm dart fix --apply --code=require_trailing_commas`. (`docs/02-conventions.md`)
11. **Imports.** Grouped `dart:` → `package:` → relative, sorted, no unused. Trim + reorder on every file edit. Modules import other modules ONLY through that module's barrel (and ideally not at all — lift to `core/`). (`docs/02-conventions.md`)
12. **Shared defs & raw primitives.** Before declaring a `const`, `typedef`, `enum`, or any raw UI primitive (`EdgeInsets`, `BorderRadius`, `Color`, `TextStyle`, `SizedBox` literal — INCLUDING `EdgeInsets.zero`, `Colors.transparent`, `SizedBox.shrink()`), check `core/constants/` and `core/helpers/` first. Token missing? STOP — surface the gap, wait for approval before inlining. (`docs/07-theming-ui.md`)

## Working principles

Apply to every prompt.

1. **Rollback point before big work.** Establish a WIP commit / `git stash` before broad refactors, cross-cutting edits, or hands-off touches. If it breaks, revert — don't fix-forward through broken state.
2. **Ask or re-fetch when unsure.** Don't guess APIs, paths, or specs. Ask the user OR re-read the source / `CLAUDE.md` / referenced `docs/`. Never fabricate.
3. **One task at a time.** Split big goals into concrete sub-tasks; complete + verify one before moving on. Surface the split first.
4. **Stop-and-note on scope creep.** Out-of-scope problem (related bug, stale dep, missing doc)? Note it, ASK before fixing. No "while I'm here" detours.
5. **Definition of done.** `fvm flutter analyze` + `fvm dart format --set-exit-if-changed .` + `fvm flutter test` (when present), each exit 0, every case pass. After editing any freezed source, also run `fvm dart run build_runner build --delete-conflicting-outputs` and commit the regenerated files. No flaky exceptions, no skipped tests, no unjustified `// ignore:`.
6. **Structure correctness.** No reverse DI (`core/` → `modules/`), no cross-module imports, hands-off files unchanged unless approved, folder layout per § Modular structure (`docs/06-modules.md`). Bend? Discuss first.
7. **Harness sync — STRICT.** Any code change that makes a claim in `CLAUDE.md` or any `docs/*.md` inaccurate — file paths, folder trees, API signatures, behaviour, examples, items mentioned BY NAME — MUST update the matching lines in the same change. Deletions count: removing a module / class / method / token leaves stale references that MUST be deleted or rewritten in the same commit.
8. **Keep harness lean.** Every `.md` here is loaded into prompt context — noise costs tokens and dilutes signal. Add only what changes assistant behaviour; trim what doesn't. Depth lives in `docs/` (load on demand). `CLAUDE.md` stays tight.
9. **Explain before bulk edits.** Narrate multi-concern file rewrites before applying — surface plan first, edit after explicit user direction.
10. **Prefer subagent dispatch — STRICT, always.** Whenever a task matches an entry in the `Sub-agent catalog` (`brainstormer`, `planner`, `reviewer`, `debugger`, `researcher`, `ui-ux-designer`, `feature-builder`, `tester`, `docs-writer`), main agent MUST dispatch that subagent — before plan, during plan, after plan, every time. Main agent handles directly ONLY when (a) no catalog entry fits the task (e.g. high-level system design, cross-step orchestration, conversational Q&A), or (b) user explicitly says "do it yourself" / "don't use a subagent". "I'll just write this small bit myself" after a plan exists = violation; dispatch the named executor for each plan step. Rationale: specialization, token economy, parallelism, protecting the main context window. (`docs/10-ai-harness.md`)

## Commands

| Action | Command |
|---|---|
| Run dev | `fvm flutter run` |
| Build APK | `fvm flutter build apk --release` |
| Build iOS | `fvm flutter build ipa --release` |
| Analyze | `fvm flutter analyze` |
| Format check | `fvm dart format --set-exit-if-changed .` |
| Format fix | `fvm dart format .` |
| Test | `fvm flutter test` |
| Codegen (freezed + json) | `fvm dart run build_runner build --delete-conflicting-outputs` |
| Codegen watch | `fvm dart run build_runner watch --delete-conflicting-outputs` |
| Trailing-commas fix | `fvm dart fix --apply --code=require_trailing_commas` |
| Get deps | `fvm flutter pub get` |
| Clean | `fvm flutter clean && fvm flutter pub get` |

## When you're stuck or scope changes

Ask the user before:

- Adding a new external dependency (`pubspec.yaml` change)
- Renaming or moving a public-API file (entity, repository interface, usecase, bloc)
- Modifying any hands-off file listed in `docs/01-architecture.md` § Hands-off boundary
- Deleting code that has external references
- Decisions that span more than one module

## References

`docs/` is the deepest reference layer — loaded on demand when this file or a rule links in for depth.

| Doc | When to read |
|---|---|
| `docs/00-overview.md` | Project intro, tech stack, reading guide |
| `docs/01-architecture.md` | Folder layout, layering, composition root, bootstrap, hands-off boundary |
| `docs/02-conventions.md` | Naming, function length, imports, trailing commas, comments, code generators, shared defs, fpdart Either |
| `docs/03-state-routing.md` | flutter_bloc patterns (Style A/B), `get_it`, `go_router`, dialogs / sheets / snackbars (`AppSnackbar`), deep links |
| `docs/04-networking.md` | `ApiClient`, `ApiResult<T>`, `Either<AppException, T>`, interceptors, envelope auto-extraction, error handler, uploads, refresh-token flow |
| `docs/05-clean-architecture.md` | Service ↔ Repository ↔ UseCase ↔ BLoC contracts, single-field usecase pattern, models extending entities |
| `docs/06-modules.md` | Module anatomy, end-to-end feature build flow, form handling |
| `docs/07-theming-ui.md` | Design tokens (`AppColors`, `AppSpacing`/`AppPadding`/`AppRadius`, `AppTypography`), shared widgets (`AppButton`, `AppSnackbar`, `BasicAppBar`, `LoadingOverlay`, `AppCircularProgress`), state matrix, a11y, responsive |
| `docs/08-platform.md` | dotenv, Firebase-readiness, secure storage, deep links (`app_links`), permissions, offline UX, dependencies |
| `docs/09-performance.md` | Mobile perf checklist + decisions (`const`, list builder, image sizing, BLoC rebuild scoping, `RepaintBoundary`) |
| `docs/10-ai-harness.md` | Layer cake, working principles in depth, hands-off protocol, harness sync, docs depth layer |
| `docs/11-module-scaffold.md` | Adding a new module from scratch (step-by-step playbook) |

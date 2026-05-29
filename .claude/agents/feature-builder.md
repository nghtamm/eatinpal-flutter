---
name: feature-builder
description: Use this agent when scaffolding a new module or adding an API endpoint to an existing one — wires entities, models, services, repositories, usecases, BLoC, page, DI in `service_locator.dart`, route in `app_router.dart`, and the per-module barrel.
tools: Read, Write, Edit, Bash, Glob, Grep, Skill
model: sonnet
skills:
  - ui-states
---


## Skill discipline (read first)

Before writing any code, invoke relevant skills via the `Skill` tool. `ui-states` is preloaded. Additionally invoke these when applicable:

- `form-handling` — module has a form / inputs
- `a11y-patterns` — any UI widget you scaffold
- `responsive-ui` — any layout
- `deep-links` — module is reachable from external URLs
- `perf-mobile` — lists, animations, image-heavy screens
- `animations` — any motion / transitions
- `offline-cache-ux` — read-heavy data that should survive offline

Do not skip skill invocation even when the task seems simple. Skills are the source of truth for eatinpal patterns.

## When to use

Two related jobs:

1. **Create a new module / feature / screen** — scaffold the 3-layer Clean Arch folder, register DI in `service_locator.dart`, register route in `app_router.dart`, generate the per-module barrel.
2. **Wire up state, services, and an API integration** for either a new or existing module — add usecases, services, request/response models, endpoint constants.

Triggers: "create a new module", "scaffold X feature", "wire up bloc for Y", "add API for Z", "wire `GET /foods`", "/scaffold-module".

For pure presentational widgets / stateless pages, use `ui-ux-designer` instead.

## Inputs

### For "create a new module"

- **`module_name`** (string, snake_case, required) — e.g. `food`, `journal`, `profile`
- **`endpoints`** (list, optional) — endpoint method names to wire in the service: `fetchFoods`, `searchFoods`, `addFood`, etc.
- **`is_list_screen`** (bool, default `false`) — when true, the page is paginated; BLoC uses Style B (single-class + enum status) for state with `items`, `page`, `hasReachedMax`.

### For "add an API endpoint" to an existing module

- **`endpoint_name`** (string, camelCase, required) — service method name (`fetchFoodDetail`, `addFood`)
- **`module`** (string, snake_case, required) — module whose service to extend
- **`method`** (`GET` | `POST` | `PUT` | `PATCH` | `DELETE`, default `GET`)
- **`path`** (string, required) — URL path; `:param` placeholders become method parameters
- **`request_fields`** (map, optional) — for `POST`/`PUT`/`PATCH` bodies; produces a request model (freezed)
- **`response_shape`** (map, optional) — fields of the response payload; produces a response model (freezed extending entity)

## What it does

### Parallel-dispatch safety

When dispatched alongside other `feature-builder`s (one module each), own only your module folder `lib/modules/<module_name>/`. The shared composition files — `app_router.dart`, `route_names.dart`, `api_endpoints.dart`, `service_locator.dart` — are touched by every builder, so they're conflict points: keep each insertion minimal and additive, and if you hit a concurrent-edit collision, STOP and report it instead of overwriting. Never invent an unfamiliar pattern to keep going — report the blocker and wait for guidance.

Note: `app_router.dart` and `service_locator.dart` are hands-off foundation files (`.claude/rules/hands-off.md`). Edits to them must remain minimal and additive; anything beyond a straightforward new-route or new-registration block requires surfacing to the user first.

### When creating a module

1. Validate `module_name` is snake_case (lowercase letters, digits, underscores; doesn't start with a digit).
2. Read `.claude/rules/modular-structure.md`, `.claude/rules/state-management.md`, `.claude/rules/code-generators.md`, and `docs/11-module-scaffold.md` (the full worked playbook).
3. If `lib/modules/<module_name>/` already exists, ASK before proceeding.
4. Create the 3-layer folder structure:

   ```
   lib/modules/<module_name>/
   ├── <module_name>.dart                # barrel — re-exports public surface
   ├── data/
   │   ├── models/<module_name>_model.dart        (freezed, extends entity, if has API)
   │   ├── services/<module_name>_service.dart    (if has API)
   │   └── repository/<module_name>_repository_impl.dart
   ├── domain/
   │   ├── entities/<module_name>_entity.dart
   │   ├── repository/<module_name>_repository.dart    (abstract)
   │   └── usecases/<verb>_<module_name>_usecase.dart  (one per use case)
   └── presentation/
       ├── bloc/
       │   ├── <module_name>_bloc.dart
       │   ├── <module_name>_event.dart        (Equatable, NEVER freezed)
       │   └── <module_name>_state.dart        (Equatable, NEVER freezed)
       ├── pages/<module_name>_page.dart
       └── widgets/                              (optional, module-private)
   ```

5. Build in the order: **domain → data → presentation → DI/route integration** (so each layer can be analyzed before the next is wired).

6. **Domain layer first:**
   - Entity: hand-written abstract class with `get` accessors.
   - Repository interface: methods returning `Future<Either<AppException, T>>`.
   - UseCase(s) extending `UseCase<T, Params>` (or `UseCaseNoParams<T>`). Single-field params: skip wrapper class (pass primitive directly).

7. **Data layer:**
   - Model: `@freezed` class with `part '<name>.freezed.dart'` + `part '<name>.g.dart'`. Implement (or extend) the entity. Add `factory fromJson`.
   - Service: `Future<Either<AppException, ApiResult<T>>>` methods calling `_client.request(...)` (constructor takes `ApiClient`).
   - RepositoryImpl: implements the abstract repository. Methods unwrap `ApiResult` and persist side effects (e.g., save tokens to `LocalStorage`). Use `.fold((left), (right))` — names `left`/`right`.
   - Run `fvm dart run build_runner build --delete-conflicting-outputs` after the model is written. Commit the generated `*.freezed.dart` + `*.g.dart`.

8. **Presentation layer:**
   - Event/State classes — regular Dart with `Equatable` and `props` overrides. Pick Style A (multi-class divergent) or Style B (single-class + enum status) per the rule.
   - BLoC: constructor injects usecases. Handlers `_onXxx(event, emit) async` use `.fold((left), (right))` to map outcome to states.
   - Page: `StatefulWidget`/`StatelessWidget` consuming BLoC via `BlocProvider(create: (_) => di<XxxBloc>(), child: _XxxView())`. Private widget builders drop the `_build` prefix.

9. **DI/route integration:**
   - Add endpoint constants to `lib/core/network/api_endpoints.dart`.
   - Append `RoutePaths.<MODULE_NAME>` + `RouteNames.<MODULE_NAME>` to `lib/app/router/route_names.dart`.
   - Add a `_register<ModuleName>Module()` function in `lib/core/di/service_locator.dart` and call it from `setupServiceLocator()`. Pattern:
     - `registerLazySingleton<XService>(() => XService(di()))`
     - `registerLazySingleton<XRepository>(() => XRepositoryImpl(di()))`
     - `registerLazySingleton(() => XxxUseCase(di()))` — one per usecase
     - `registerFactory(() => XBloc(usecase: di(), …))`
   - Add a `GoRoute(path: RoutePaths.X, name: RouteNames.X, builder: …)` to `lib/app/router/app_router.dart`.
   - Re-export the module's public surface from `lib/modules/<module_name>/<module_name>.dart` (one `export` per file in `data/`, `domain/`, `presentation/`).
10. Run `fvm flutter analyze`. Report issues. If freezed model edits are pending regeneration, mention the `build_runner` command.

11. Print a "next steps" checklist:
    - Replace placeholder UI in `<ModuleName>Page` with real screens (or dispatch to `ui-ux-designer`).
    - Add tests (dispatch `tester` for usecase/repository/BLoC/widget coverage).
    - Update `_guard` in `app_router.dart` if the route should be public.

### When adding an API endpoint to an existing module

1. Validate the target module exists. If not, suggest running scaffolding first.
2. Append the path constant to `ApiEndpoints` in `lib/core/network/api_endpoints.dart`.
3. If `request_fields` is non-empty, create a freezed request model in `lib/modules/<module>/data/models/`. Regenerate.
4. If `response_shape` is non-empty, create a freezed response model that extends the corresponding domain entity (create the entity in `domain/entities/` if missing). Regenerate.
5. Add the service method in `<module>_service.dart` that calls `_client.request<T>(...)`.
6. Add a repository method (and abstract method on the interface) that unwraps the `ApiResult` and returns `Either<AppException, T>`.
7. Add a usecase that calls the new repository method.
8. Register the new usecase in `service_locator.dart` and inject into the relevant BLoC.
9. Run `fvm flutter analyze`. Print follow-ups (write tests, wire UI).

## Critical patterns (eatinpal-specific)

- **fpdart Either**: `result.fold((left) { ... }, (right) { ... })` — params named `left`/`right`. AVOID `switch (result) { case Left ... case Right }`.
- **Single-field usecase param**: skip wrapper class. `class XUseCase implements UseCase<String, String>` with `call(String email)`.
- **BLoC**: register with `registerFactory` (fresh per page). Services / repositories / usecases → `registerLazySingleton`.
- **Models extend entity**: `class UserModel with _$UserModel implements UserEntity { … }`.
- **Naming**: constants `UPPER_SNAKE_CASE`; private widget-builder helpers drop `_build` prefix.

## Anti-patterns

- Don't use `freezed` for BLoC events/states — use plain classes + `Equatable`.
- Don't import individual files from another module — use that module's barrel, or lift to `core/`.
- Don't touch hands-off files (`.claude/rules/hands-off.md`) without surfacing it first.
- Don't skip `fvm dart run build_runner build --delete-conflicting-outputs` after freezed edits.
- Don't forget to add the module's exports to the barrel `<name>.dart`.
- Don't forget DI registration — a missing `di.registerXxx` throws at runtime.
- Don't add new dependencies to `pubspec.yaml` without explicit user approval.

## See also

- `docs/11-module-scaffold.md` — full step-by-step playbook with a worked `food` module example
- `docs/05-clean-architecture.md` — Service ↔ Repository ↔ UseCase ↔ BLoC contracts
- `docs/06-modules.md` — module pattern + barrel
- `docs/04-networking.md` — `ApiClient` + `ApiResult<T>` + `Either<AppException, T>`
- `.claude/rules/modular-structure.md` — folder shape + barrel + cross-module ban
- `.claude/rules/state-management.md` — BLoC styles, DI, error flow
- `.claude/rules/code-generators.md` — freezed model contract
- `lib/modules/auth/` — full reference implementation
- `ui-ux-designer` — for stateless view building
- `tester` — for adding regression tests

# Conventions

Code style and structural conventions: naming, function length, imports, trailing commas, comments, shared definitions, code generators, and the fpdart `Either` contract. Every rule listed here also appears in `CLAUDE.md` § Critical rules — this document is the narrative reference.

## Naming

| Element | Convention | Example |
|---|---|---|
| File | `snake_case.dart` | `login_page.dart`, `auth_repository_impl.dart` |
| Folder | `snake_case` | `core/network/interceptors/` |
| Class / Enum / Typedef / Mixin | `PascalCase` | `AuthBloc`, `AppException`, `RestMethod` |
| Method / parameter / local variable | `camelCase` (short — 1 word preferred, 2-3 max) | `submit()`, `email`, `isLoading` |
| Global constant (top-level OR `static const` in const-only class) | `UPPER_SNAKE_CASE` | `SIZED_BOX_H16`, `AppColors.PRIMARY`, `_ACCESS_TOKEN_KEY`, `AppPadding.BASE` |
| Enum value | `UPPER_SNAKE_CASE` | `RestMethod.GET`, `AppSnackbarType.SUCCESS`, `AppButtonVariant.PRIMARY` |
| Private member | prefix `_` | `_isSubmitting`, `_ACCESS_TOKEN_KEY` |
| Boolean | prefix `is`, `has`, `can`, `should` | `isLoading`, `hasMore`, `canRetry` |
| Test file | `<src>_test.dart` | `login_bloc_test.dart` |
| Route path constant | `UPPER_SNAKE_CASE` in `abstract final class` | `RoutePaths.LOGIN` |
| Route name constant | `UPPER_SNAKE_CASE` in `abstract final class` | `RouteNames.LOGIN` |

`UPPER_SNAKE_CASE` applies to top-level constants AND `static const` fields inside const-only classes (`AppColors`, `AppPadding`, `AppRadius`, `AppTypography`, `RoutePaths`, `ApiEndpoints`). The codebase deliberately disables `constant_identifier_names` (or treats it as info-level) so these don't need per-line `// ignore` comments.

### Private widget-builder helpers — DROP `_build` prefix

Page-internal helper methods that return a `Widget` use bare names without the `_build` prefix:

```dart
class LoginPage extends StatelessWidget {
  Widget _banner() => ...;          // ✅
  Widget _form() => ...;            // ✅
  Widget _footer() => ...;          // ✅
}
```

```dart
// ❌
Widget _buildBanner() => ...;
Widget _buildForm() => ...;
```

This does NOT apply to the framework's `build(BuildContext context)` override — that keeps its name.

### Examples

```dart
// File: lib/modules/auth/presentation/bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;                      // private member with _
  bool _isSubmitting = false;                     // private camelCase

  AuthBloc({required LoginUseCase login}) : _login = login, super(const AuthInitial()) {
    on<AuthLoginSubmitted>(_onLogin);
  }

  Future<void> _onLogin(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    final result = await _login(LoginParams(email: event.email, password: event.password));
    _isSubmitting = false;
    result.fold(
      (left) => emit(AuthFailure(left.message)),
      (right) => emit(AuthAuthenticated(right)),
    );
  }
}

// File: lib/core/constants/app_colors.dart
abstract final class AppColors {
  static const Color PRIMARY = Color(0xFF34C77B);     // UPPER_SNAKE_CASE
  static const Color ERROR = Color(0xFFEF4444);
}
```

### Incorrect

```dart
class authBloc extends Bloc<...> { }              // ❌ class camelCase
final bool IsLoading = false;                     // ❌ var PascalCase
bool issubmitting = false;                        // ❌ no camelCase, no isXxx prefix

abstract final class AppColors {
  static const Color primary = Color(0xFF34C77B); // ❌ should be PRIMARY
}

Widget _buildHeader() => ...;                     // ❌ drop _build
```

## Function length

| Limit | Meaning |
|---|---|
| **Target ~100 lines** | Comfortable single-screen read; goal for every method |
| **Soft upper bound ~300 lines** | Estimate, not a hard cap. Going slightly above is fine when the unit is genuinely cohesive (one purpose, no missing abstraction). Going significantly above is a smell. |

No `flutter analyze` rule enforces this — judgment in context.

When a function feels too long:

- **Extract private helpers** in the same class.
- **Extract sub-widgets** when `build()` grows. Each sub-widget / extracted method ≤ 100 lines.
- **Move pure logic** to `core/helpers/`.
- **Split a service / repository method** if it does multiple things.

### Where the estimate doesn't apply

- **Lookup tables / data declarations** — multi-hundred-line `static const Map<String, ...>` with no logic.
- **Generated code** (`*.freezed.dart`, `*.g.dart`) — excluded from the analyzer via `analysis_options.yaml`.
- **`switch` expression on a large enum** — each case is one line; total grows linearly.
- **Pure UI `build()` describing one cohesive layout** — extract sub-widgets first; if the remainder still feels like one unit, leave it.

### Example — decomposed `build`

```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(title: Text('Sign in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.BASE),
          child: Column(
            children: [
              _banner(),
              SIZED_BOX_H24,
              const _LoginForm(),
              SIZED_BOX_H16,
              _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner() => ...;
  Widget _footer(BuildContext context) => ...;
}

class _LoginForm extends StatefulWidget { ... }   // separate widget; module-private
```

## Imports

### Order

Group imports in this order, separated by blank lines:

1. `dart:` imports
2. `package:` imports (including this project — `package:eatinpal/...`)
3. Relative imports (`./`, `../`)

Within each group, sort alphabetically.

Note: this codebase uses `package:eatinpal/...` for everything inside `lib/` — relative imports are rare (mostly within a freezed model and its part file). Stick to `package:` form for clarity.

```dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';
import 'package:eatinpal/core/network/api_methods.dart';
import 'package:eatinpal/core/network/api_result.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/data/models/credentials_model.dart';
import 'package:eatinpal/modules/auth/data/models/user_model.dart';
import 'package:fpdart/fpdart.dart';
```

### Optimise on every edit

Before saving a file you touched:

1. **Trim unused** — remove every `import` whose symbols aren't referenced. `fvm flutter analyze` reports them as `unused_import`; treat as errors.
2. **Reorder** — apply the three-group rule. `dart format` does NOT reorder imports.
3. **Merge duplicates** — only one `import` per package per file.
4. **Prefer full imports** — `import 'package:foo/foo.dart';` over `show` / `hide`. Use `as` aliases only to resolve a real symbol clash.

Tooling:

- `fvm dart fix --apply` auto-handles some unused imports.
- IDE "Optimize Imports" command (VS Code Dart extension, IntelliJ Dart plugin) reorders + trims in one step.
- `fvm flutter analyze` reports `unused_import` warnings — treat as hard errors.

### Layering

Allowed directions (also enforced by the `modular-structure` rule — see `01-architecture.md`):

- `modules/<feature>/presentation/` → `modules/<feature>/domain/` ✅
- `modules/<feature>/data/` → `modules/<feature>/domain/` ✅
- `modules/<feature>/domain/` → `modules/<feature>/data/` ❌
- `modules/<feature>/` → `core/` ✅
- `core/<X>/` → `core/<Y>/` ✅ (within core, individual files — no barrel)
- `lib/main.dart` / `lib/app/` → anything ✅ (composition root)
- `lib/core/di/service_locator.dart` → `modules/<X>/<X>.dart` ✅ (composition root for DI)
- `modules/A/` → `modules/B/` ❌
- Any other `core/<X>/` → `modules/` ❌

### Cross-module rule

Modules MUST import other modules ONLY through that module's barrel:

```dart
// ❌ NEVER reach into another module's internals
import 'package:eatinpal/modules/auth/data/models/user_model.dart';

// ✅ Through the barrel (still discouraged — prefer to lift to core)
import 'package:eatinpal/modules/auth/auth.dart';
```

But the cleanest answer is almost always: lift the shared piece to `core/`, or expose it through a usecase. Direct cross-module imports — even via barrel — are a yellow flag in code review.

## Trailing commas

Add a trailing comma after the last item in any multi-line:

- Argument list (function / constructor call)
- Parameter list (function / method / constructor declaration)
- Collection literal (`[]`, `{}`, Set, Map)
- Multi-line type argument list (rare)
- Pattern with multiple sub-patterns

Single-line constructs do NOT need a trailing comma.

```dart
// ✅ Multi-line — trailing comma
final user = UserEntity(
  id: '1',
  email: 'a@b.com',
  name: 'Jane',
  avatarURL: null,
  emailVerified: true,
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// ✅ Single-line — no trailing comma needed
const point = Offset(1, 2);
const list = [1, 2, 3];
debugPrint('hello');
```

Enforced by `require_trailing_commas` (or equivalent) — `info`-level diagnostic treated as a hard gate. Fix with:

```bash
fvm dart fix --apply --code=require_trailing_commas
```

### Why

- A trailing comma signals to `dart format` that the multi-line construct should stay multi-line.
- Diffs become smaller — adding a new argument changes one line, not two.
- Reviewers can copy / paste / reorder without worrying about trailing punctuation.

### Interaction with `dart format`

- `dart format` keeps trailing commas where they exist on multi-line constructs.
- `dart format` does NOT add a trailing comma if missing (that's the lint's job).
- `dart format` may strip a trailing comma from a single-line construct.
- Workflow: format first to settle line breaks, then `dart fix --apply --code=require_trailing_commas` if any survived multi-line without a comma.

## Comments

Default: **write none**. Only add a comment when the WHY is non-obvious:

- A hidden constraint (e.g. "API requires the X-Verification header for /auth/verify")
- A subtle invariant (e.g. "must run after `dotenv.load()` — needs BASE_URL")
- A workaround for a specific bug (link the issue if relevant)
- Behaviour that would surprise a reader (e.g. `// Cold-start carrier: go_router không hỗ trợ initialExtra, dùng storage làm bridge một lần.` — actual comment in `main.dart`)

Don't comment WHAT the code does — well-named identifiers already do that.

Don't reference:

- The current task / PR / commit
- Callers ("used by X", "added for the Y flow")
- Past versions ("// removed: foo() — replaced by bar()")

These belong in the PR description, not in code, and rot as the codebase evolves.

### Docstring style

Use `///` (dartdoc) for public class / method / function declarations that have non-obvious contracts. Single-line where possible. NEVER multi-paragraph docstrings inside a function body.

```dart
/// Returns `true` if the JWT's exp claim is in the past, OR if the token is malformed.
bool isJWTExpired(String token) { /* ... */ }

/// HTTP entry point. All API calls go through this class via [request] or [upload].
/// Returns [Either] with [AppException] on the left and an envelope-wrapped [ApiResult] on the right.
class ApiClient { /* ... */ }
```

Inside functions, prefer rewriting the code to be self-explanatory over adding a comment.

## Code generators

This project uses freezed + json_serializable for data models. They are the ONLY allowed code generators. Everything else (BLoC events/states, entities, usecases, all of `core/`) is hand-written.

### ✅ Allowed

| Generator | Command | What it does | Output |
|---|---|---|---|
| freezed + json_serializable | `fvm dart run build_runner build --delete-conflicting-outputs` | Generates `*.freezed.dart` (copyWith, ==, hashCode, toString) and `*.g.dart` (fromJson/toJson) for `@freezed` and `@JsonSerializable()` classes | Next to source — COMMITTED |
| Watch mode | `fvm dart run build_runner watch --delete-conflicting-outputs` | Same, runs continuously | Same |

Re-run after editing any freezed source (model). Generated files ARE committed — fresh clones don't need to regen.

### ❌ NOT for BLoC

**Never use freezed for BLoC events or states.** They are hand-written `Equatable` classes. See `03-state-routing.md` § BLoC style guide.

### ❌ Not for entities

Domain entities are plain Dart classes (with `Equatable` if equality matters). Keeping them codegen-free preserves the "domain knows nothing about external packages" principle.

### Model template (freezed + implements entity)

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

Conventions:
- `@freezed abstract class FooModel with _$FooModel implements FooEntity` — `implements`, not `extends`, because freezed already controls the class shape.
- `@JsonKey(name: 'snake_case_name')` to map backend `snake_case` JSON to Dart `camelCase` fields.
- Both `*.freezed.dart` and `*.g.dart` are committed.

### When forbidden codegen would creep in

The only generator allowed is `build_runner` driving `freezed` + `json_serializable`. Don't add:

- `mockito` (`@GenerateMocks`) — write hand-written test doubles or use `mocktail` (no codegen) if a dep is genuinely needed (requires user approval).
- `injectable` — `get_it` registration in `service_locator.dart` is explicit by design.
- `auto_route` — `go_router` declarative routes are the standard.

### When you genuinely need a new generator

Surface it BEFORE adding the dependency. Discuss:

- What problem does it solve that hand-writing can't?
- What's the maintenance cost (codegen step, learning curve)?
- Can the team commit the output?

If approved, document it in `CLAUDE.md` and the relevant doc.

## Shared definitions

Before declaring a new constant, typedef, enum, or raw UI primitive, check `core/` first.

| Symbol | Home |
|---|---|
| App-wide constant (duration, page size, limit) | `core/constants/` — new file or add to `app_spacing.dart` / appropriate token file |
| Color | `core/constants/app_colors.dart` (`AppColors.PRIMARY`) |
| Spacing / padding / margin | `core/constants/app_spacing.dart` (`AppPadding.BASE` for double, `SIZED_BOX_H16` for `SizedBox(height: 16)`) |
| Border radius | `core/constants/app_spacing.dart` (`AppRadius.MD`) |
| Text style | `core/constants/app_typography.dart` (`AppTypography.HEADING_1` etc.) |
| Theme | `core/constants/app_theme.dart` |
| Cross-module enum | `core/constants/` or a dedicated `enums.dart` |
| Storage key | private `_UPPER_SNAKE_CASE` constant inside the relevant `core/local/` impl |
| Route path | `RoutePaths` in `app/router/route_names.dart` |
| Route name | `RouteNames` in `app/router/route_names.dart` |
| API endpoint | `ApiEndpoints` in `core/network/api_endpoints.dart` |
| Shared widget used by 2+ modules | `core/widgets/` |
| Module-private magic number | inline `static const _NAME` |

**Use what's there.** Never duplicate or re-declare a value that already exists in `core/`.

**Promote when scope widens.** If a value or alias is (or could be) referenced from more than one file — or its meaning is app-wide — declare it in the appropriate `core/` file, not inline.

Keep inline ONLY when scope is genuinely a single file AND the symbol is private (`_LOCAL_THING`).

### Raw primitive rule — ABSOLUTE

**Principle.** Any Flutter / Dart primitive whose value carries a *design decision* — layout, spacing, color, radius, typography, animation duration, opacity, elevation, etc. — MUST come from a `core/constants/` token. Bypassing the token system for "just this one tiny case" defeats the purpose.

**Mental test:**

1. **Would this value plausibly change if the design changed?** Spacing scale, color palette, radius scale, font sizes, transition durations. → YES → must come from a token. NO exceptions.
2. **Is it a "neutral / convenience" form?** `EdgeInsets.zero`, `BorderRadius.zero`, `Colors.transparent`, `SizedBox.shrink()`, `Duration.zero`. → STILL YES, must come from a token. These are design decisions at the zero / neutral point of the scale, not exceptions. Convenience constructors bypass the token system in exactly the same way `EdgeInsets.all(16)` does.
3. **Is it a non-design value** (e.g. timeout `Duration` for HTTP, `int` for page size)? → Belongs in `core/constants/` as a named constant, still mandatory to centralise.
4. **Is the value genuinely private to one file AND not design-relevant** (e.g. an internal compute threshold)? → Inline `static const _NAME` is allowed.

If you can't place the value in 1–3, it's likely (4). When in doubt, ASK before inlining.

**Decision flow:**

- Token exists → use it.
- Token doesn't exist → STOP. Surface the gap with a proposed token name + location. Wait for user approval before inlining anything.
- Never inline a raw design primitive — not even temporarily, not even as a `// TODO`.

Example surface prompts to the user:

> "Need `EdgeInsets.zero` for [X]. `AppSpacing` already exposes `SPACE_ZERO` for the same intent at zero-height — use that, or add `AppPadding.ZERO_INSETS = EdgeInsets.zero`. Which?"

> "Need spacing 42 for [X]. Not in `AppSpacing`. Propose `SIZED_BOX_H42` and `AppPadding.<name> = 42`. Approve?"

> "Need transparent color for [X]. Already have `AppColors.TRANSPARENT`. Use that."

### What goes where (decision matrix)

| Symbol | Home |
|---|---|
| App-wide HTTP timeout / page size / limit | `core/constants/` (new file or appropriate existing) |
| Top-level `typedef` used in ≥ 1 module or in `core/` | `core/helpers/` (e.g. `typedefs.dart`) or local file if narrow |
| Cross-module enum | `core/constants/` |
| Spacing / padding / gap | `AppPadding.*` (double) + `SIZED_BOX_*` (Widget) in `app_spacing.dart` |
| Border radius | `AppRadius.*` in `app_spacing.dart` |
| Color | `AppColors.*` in `app_colors.dart` |
| Text style | `AppTypography.*` in `app_typography.dart` |
| Storage key | private `_KEY_<NAME>` inside the relevant `core/local/` impl |
| Route path | `RoutePaths.*` |
| Route name | `RouteNames.*` |
| API endpoint | `ApiEndpoints.*` |
| Shared widget used in ≥ 2 modules | `core/widgets/` |
| Private-to-file magic number with no reuse potential | inline `static const _NAME` (private) |

### Examples

```dart
// ✅ Reuse existing tokens
Padding(padding: const EdgeInsets.all(AppPadding.BASE), child: ...)
Container(margin: const EdgeInsets.symmetric(horizontal: AppPadding.LG), child: ...)
SIZED_BOX_H24
Container(decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(AppRadius.MD),
  color: AppColors.SURFACE_CARD,
))
Text('Hello', style: AppTypography.BODY_MEDIUM)

// ❌ Raw literals
Padding(padding: const EdgeInsets.all(16), child: ...)           // ❌ use AppPadding.BASE
const SizedBox(height: 24)                                        // ❌ use SIZED_BOX_H24
Container(decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(12),                        // ❌ use AppRadius.MD
  color: const Color(0xFFFFFFFF),                                 // ❌ use AppColors.WHITE
))
Text('Hello', style: TextStyle(fontSize: 14))                     // ❌ use AppTypography.BODY_MEDIUM
```

### Don't shadow framework typedefs

```dart
typedef VoidCallback = void Function();      // ❌ shadows dart:ui's VoidCallback
```

Flutter / Dart core already defines `VoidCallback`, `ValueChanged<T>`, `WidgetBuilder`, `AsyncCallback`, and many more. Import from `dart:ui` / `package:flutter/foundation.dart` / `package:flutter/widgets.dart` instead.

### Naming reminder for shared defs

- Token classes' fields → `UPPER_SNAKE_CASE` (or for `AppPadding` / `AppRadius` doubles also `UPPER_SNAKE_CASE`)
- Typedefs → `PascalCase`
- Inline private constants → `_UPPER_SNAKE_CASE` with `_` prefix

## fpdart `Either<AppException, T>`

The result contract throughout `domain/` and `presentation/`. Repositories and usecases return `Future<Either<AppException, T>>`. Services return `Future<Either<AppException, ApiResult<T>>>` (envelope-wrapped — see `04-networking.md`).

### Unwrapping — always `.fold((left) => ..., (right) => ...)`

```dart
final result = await loginUseCase(LoginParams(email: email, password: password));

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

**Always name the params `left` and `right`** — NOT domain names like `error` / `user`. The reason: scanning code is faster when the failure / success channel is always called the same thing, regardless of what's inside.

### ❌ Avoid pattern matching

```dart
switch (result) {
  case Left(value: final l): ...
  case Right(value: final r): ...
}
```

Verbose, less idiomatic in fpdart, and the names diverge from the convention. Stick to `.fold(...)`.

### Single-field usecase params — skip the wrapper

When a usecase takes only ONE field, pass the primitive directly. Do NOT wrap it in a single-field params class.

```dart
// ✅ Single field — primitive directly
class ResendUseCase extends UseCase<String, String> {
  final AuthRepository _repository;
  ResendUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(String email) {
    return _repository.resend(email: email);
  }
}

// Call site
final result = await resend(email);
```

```dart
// ❌ One-field wrapper — unnecessary boilerplate
class ResendParams {
  final String email;
  const ResendParams({required this.email});
}
class ResendUseCase extends UseCase<String, ResendParams> { ... }
```

Multi-field params still get a class (`LoginParams`, `RegisterParams`):

```dart
// ✅ Multi-field — wrap in a params class
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
```

### No-params usecases — `UseCaseNoParams<T>`

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
final result = await getProfile();
```

`NoParams` (defined in `core/usecase/usecase.dart`) exists for symmetry but you typically just use `UseCaseNoParams<T>` instead.

## Decision flow when writing new code

When you're about to write a `const`, `static const`, `typedef`, or any raw UI primitive:

1. **Is it a UI primitive** (`EdgeInsets`, `BorderRadius`, `Color`, `TextStyle`, `SizedBox` literal)? → look in `core/constants/`. Token exists → use it. No token → ASK before inlining.
2. **Is it a code-level constant or typedef?** → look in `core/constants/` / `core/helpers/`. Already there → use it.
3. **Is it private to this file AND will stay that way?** → declare inline with `_` prefix.
4. **Otherwise** → add to the appropriate `core/` file and import.

When you spot an inline literal that meets criterion 1 or 4 during a refactor, promote it.

## See also

- `01-architecture.md` — layering rules + hands-off boundary
- `03-state-routing.md` — BLoC patterns, `flutter_bloc` events / states (NEVER freezed)
- `04-networking.md` — `Either<AppException, ApiResult<T>>` service contract
- `05-clean-architecture.md` — service → repository → usecase → bloc fpdart flow
- `07-theming-ui.md` — token usage examples, shared widgets
- `CLAUDE.md` § Critical rules — rules 1, 2, 3, 7, 10, 11, 12
- `analysis_options.yaml` — lint config

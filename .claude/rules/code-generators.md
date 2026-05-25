---
name: code-generators
description: Allowed generators: `freezed`, `json_serializable`, `build_runner`. Forbidden: `mason`, freezed for BLoC events/states. Generated `*.freezed.dart` and `*.g.dart` ARE committed. Re-run build_runner after editing freezed sources.
---

# Rule: Code generators

## Constraint

EatinPal uses `freezed` + `json_serializable` for data models. Generated outputs are committed to git. Re-run `build_runner` after editing any freezed source.

### ✅ Allowed generators

| Generator | Where it's used | Output |
|---|---|---|
| `freezed` / `freezed_annotation` | `lib/modules/*/data/models/*.dart` — data models | `*.freezed.dart` (committed) |
| `json_serializable` / `json_annotation` | Same models as above | `*.g.dart` (committed) |
| `build_runner` | Toolchain that runs the codegens above | (no file output — runs the others) |

Regenerate after editing any freezed source:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.freezed.dart`, `*.g.dart`) ARE checked into git. CI does not regenerate; contributors do. Re-run after every edit to a freezed source.

### ❌ Forbidden uses

| Misuse | Why |
|---|---|
| `freezed` on BLoC events/states | BLoC events/states use plain classes with `Equatable` — see `.claude/rules/state-management.md` |
| `freezed` on entities in `domain/` | Entities are hand-written abstract types — models in `data/` extend them. Adding freezed to entities couples domain to a data-layer codegen. |
| `mason` / `mason_brick` | Scaffolding is via `feature-builder` agent + `project-customize` skill, not a CLI generator. |
| Any other annotation-driven codegen | Discuss before adding — keep the toolchain minimal. |

## Model contract

Data models in `lib/modules/<name>/data/models/`:

- Use `@freezed` annotation
- EXTEND (or implement) the corresponding entity in `lib/modules/<name>/domain/entities/`
- Generate `fromJson` via `json_serializable`
- Generated files (`*.freezed.dart`, `*.g.dart`) committed

## Why

- Freezed eliminates boilerplate (`copyWith`, `==`, `hashCode`, pattern matching) for ~20-line model declarations.
- `json_serializable` is the de-facto Flutter JSON pattern — readable, IDE-jump-friendly.
- Generated files committed means: no CI codegen step, no contributor "did you forget to run build_runner" gotchas, full IDE intellisense works on fresh clone.
- BLoC events/states stay hand-written + Equatable to keep them framework-free and avoid codegen lag on every state shape tweak.

## Examples

### ✅ Correct — freezed data model extending domain entity

```dart
// lib/modules/auth/domain/entities/user_entity.dart
abstract class UserEntity {
  String get id;
  String get email;
  String get name;
  bool get emailVerified;
}
```

```dart
// lib/modules/auth/data/models/user_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:eatinpal/modules/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel implements UserEntity {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    @Default(false) bool emailVerified,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

After editing the above, run:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
git add lib/modules/auth/data/models/user_model.freezed.dart \
        lib/modules/auth/data/models/user_model.g.dart
```

### ✅ Correct — BLoC event/state with Equatable (NOT freezed)

```dart
// lib/modules/auth/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

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
```

### ❌ Incorrect — freezed on BLoC state

```dart
@freezed                                                       // ❌
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.success(String message) = AuthSuccess;
}
```

→ Use Equatable instead. See `.claude/rules/state-management.md`.

### ❌ Incorrect — freezed on a domain entity

```dart
// lib/modules/auth/domain/entities/user_entity.dart
@freezed                                                       // ❌ entities are hand-written abstract types
class UserEntity with _$UserEntity {
  const factory UserEntity({ ... }) = _UserEntity;
}
```

Entity is the contract; model is the codegen-backed implementation. Don't mix them.

## Workflow when editing a freezed model

```
$EDITOR lib/modules/auth/data/models/user_model.dart    # change shape
fvm dart run build_runner build --delete-conflicting-outputs
git add lib/modules/auth/data/models/user_model.dart \
        lib/modules/auth/data/models/user_model.freezed.dart \
        lib/modules/auth/data/models/user_model.g.dart
fvm flutter analyze
```

Forgetting to regenerate is a common rookie mistake — the model and generated files drift, and the analyzer complains about missing members.

## When you genuinely need a new generator

Surface it BEFORE adding the dependency:

- What problem does it solve that hand-writing or the current codegens can't?
- What's the maintenance cost (codegen step, learning curve)?
- Can outputs be committed?

If approved, update the **Allowed** table here and add the dep to `pubspec.yaml`.

## See also

- `docs/02-conventions.md` § Models — full contract
- `pubspec.yaml` — `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable`, `build_runner`
- `.claude/rules/state-management.md` — why BLoC stays hand-written
- `lib/modules/auth/data/models/` — reference implementations

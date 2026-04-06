---
description: Flutter coding standards and architecture rules for EatinPal
paths: ["lib/**/*.dart"]
---

# Flutter Rules

## Architecture
- Follow clean architecture: data -> domain -> presentation per module
- Services call ApiClient directly, repositories delegate to services
- UseCases return `Either<AppException, T>` via fpdart
- BLoC pattern for state management (no Cubit unless trivially simple)
- BLoC events/states use Equatable, NOT freezed
- Choose BLoC state/event style based on complexity (see BLoC Style Guide below)

## Code Quality
- All constants declared outside classes/functions must be SNAKE_UPPERCASE
- Use trailing commas for multi-line expressions
- Keep functions short - extract logic into helpers
- Always handle null safety properly
- Use `const` constructors wherever possible

## Models
- Use freezed + json_serializable for data models
- Models must extend their corresponding domain entity
- Never use freezed for BLoC events or states

## BLoC Style Guide

Two styles — pick based on the state shape:

### Style A: Multi-class (default for divergent states)
Use when each state carries **different data** (e.g. auth: Initial has nothing, Authenticated has user, Error has message).

```dart
// Events
abstract class FooEvent extends Equatable { ... }
class FooStarted extends FooEvent { ... }
class FooSubmitted extends FooEvent { final String value; ... }

// States
abstract class FooState extends Equatable { ... }
class FooInitial extends FooState { ... }
class FooLoading extends FooState { ... }
class FooSuccess extends FooState { final Data data; ... }
class FooFailure extends FooState { final String message; ... }
```

### Style B: Single-class with enum (for shared fields)
Use when states share **most of the same fields** and only differ by status (e.g. a list screen: always has items + pagination, status just toggles loading/loaded/error).

```dart
enum FooStatus { initial, loading, success, failure }

class FooState extends Equatable {
  final FooStatus status;
  final List<Item> items;
  final String? error;
  final int page;

  const FooState({
    this.status = FooStatus.initial,
    this.items = const [],
    this.error,
    this.page = 0,
  });

  FooState copyWith({ ... });

  @override
  List<Object?> get props => [status, items, error, page];
}
```

### Quick decision
| Condition | Style |
|---|---|
| States carry very different data shapes | A (multi-class) |
| States share most fields, differ by status | B (single-class) |
| Only 2-3 simple states | A (simpler) |
| Many fields persisted across status changes | B (avoids data loss) |

## Imports
- Import other modules via their barrel export file only
- Core files are imported individually (no barrel export for core)
- Prefer relative imports within the same module

---
name: function-length
description: Aim for ~100 lines per function/method/widget builder; ~300 is the soft upper bound. Refactor by extracting private helpers, sub-widgets, or utilities in `core/helpers/`.
---

# Rule: Function length

## Constraint

Every function, method, constructor, top-level function, and private widget-builder helper:

- **Target: ~100 lines** — comfortable single-screen read
- **Soft upper bound: ~300 lines** — going slightly above is fine when genuinely cohesive; going significantly above is a smell

No hard analyzer rule enforces this; the reviewer judges in context.

When a function feels too long, refactor:

- Extract private helpers in the same class
- Extract sub-widgets when `build()` (or a page's helper like `_content()`) grows
- Move pure logic to `lib/core/helpers/`
- Split a service method into smaller methods if it does multiple things

Don't count blank lines or pure comment lines.

## Why

- One-screen code reads faster and has fewer errors.
- Long functions usually do multiple things — splitting reveals missing abstractions.
- BLoC handlers, services, and widget builders compose better when small.
- Long widget builders cause deeper trees and harder rebuild scoping.

## Examples

### ✅ Correct — focused BLoC handler, ~25 lines

```dart
Future<void> _onLogin(
  AuthLoginSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());
  final result = await _login(
    LoginParams(email: event.email, password: event.password),
  );
  result.fold((left) {
    if (left is ForbiddenException) {
      emit(AuthRequiresVerification(left.message));
    } else {
      emit(AuthFailure(left.message));
    }
  }, (right) => emit(AuthAuthenticated(right)));
}
```

### ❌ Incorrect — 250-line `build()`

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(/* 30 lines of inline app bar */),
    body: Column(
      children: [
        Container(/* 40 lines of inline header */),
        Expanded(
          child: ListView.builder(
            itemBuilder: (ctx, i) => Card(/* 60 lines of inline item */),
          ),
        ),
        Container(/* 50 lines of inline bottom bar */),
      ],
    ),
    floatingActionButton: FloatingActionButton(/* 30 lines */),
  );
}
```

### ✅ Correct — same UI, decomposed via private builders

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: const BasicAppBar(),
    body: SafeArea(
      child: Column(
        children: [
          _header(),
          Expanded(child: _itemList()),
          _bottomBar(),
        ],
      ),
    ),
    floatingActionButton: _fab(),
  );
}

Widget _header() { /* ~30 lines */ }
Widget _itemList() { /* ~40 lines */ }
Widget _bottomBar() { /* ~30 lines */ }
Widget _fab() { /* ~20 lines */ }
```

Private widget-builder helpers drop the `_build` prefix — `_header()` not `_buildHeader()`. See `.claude/rules/naming-conventions.md`.

## When the estimate doesn't apply

These cases scale past the target and don't need refactor:

- **Lookup tables / data declarations** — multi-hundred-line `static const Map<...>` or list literals with no logic.
- **Generated code** (`*.freezed.dart`, `*.g.dart`) — excluded from analyzer.
- **Pure UI build methods that genuinely describe one cohesive layout** — extract sub-widgets first; if the result still feels like one unit, leave it.

## See also

- `docs/02-conventions.md` § Function length
- `.claude/rules/naming-conventions.md` — widget-builder naming
- `.claude/agents/reviewer.md` — reviewer flags violations

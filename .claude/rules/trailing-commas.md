---
name: trailing-commas
description: Always include a trailing comma after the last argument in multi-line argument lists, parameter lists, and collection literals. Enforced by `require_trailing_commas` lint.
---

# Rule: Trailing commas

## Constraint

Add a trailing comma after the last item in any multi-line:

- Argument list (function / constructor call)
- Parameter list (function / method / constructor declaration)
- Collection literal (`[]`, `{}`)
- Pattern with multiple sub-patterns

The lint `require_trailing_commas: true` flags missing commas. Fix before merging.

Single-line collections / argument lists do NOT need a trailing comma — the rule applies only when the call spans multiple lines.

## Why

- A trailing comma signals to `dart format` that the call/list/parameter list should stay multi-line. Without it, format may collapse to a single line.
- Diffs become smaller: adding a new argument changes one line, not two.
- Reviewers can copy/paste/reorder lines without worrying about trailing punctuation.

## Examples

### ✅ Correct — multi-line, trailing comma

```dart
context.read<AuthBloc>().add(
  AuthLoginSubmitted(
    email: _emailController.text.trim(),
    password: _passwordController.text,
  ),
);
```

```dart
return Column(
  children: [
    _title(),
    SIZED_BOX_H12,
    _subtitle(),
  ],
);
```

```dart
Future<Either<AppException, ApiResult<UserModel>>> fetchUser({
  required int id,
  bool includeProfile = false,
}) {
  return _client.request<UserModel>(
    endpoint: ApiEndpoints.userDetail(id),
    method: RestMethod.GET,
    parser: (data) => UserModel.fromJson(data as Map<String, dynamic>),
  );
}
```

### ✅ Correct — single-line, no trailing comma

```dart
const offset = Offset(1, 2);
final list = [1, 2, 3];
debugPrint('hello');
```

### ❌ Incorrect — multi-line without trailing comma

```dart
final params = LoginParams(
  email: 'x@y.com',
  password: 'pass'    // ❌ missing trailing comma
);
```

`fvm flutter analyze` reports:

```
info • Missing a required trailing comma • lib/.../*.dart:LL:CC • require_trailing_commas
```

### ❌ Incorrect — trailing comma on a single-line list

```dart
const list = [1, 2, 3,];     // ❌ format may strip it
```

## How to fix violations

```bash
fvm dart fix --apply --code=require_trailing_commas
fvm flutter analyze
```

## Interaction with `dart format`

- `fvm dart format` keeps trailing commas where they exist on multi-line constructs.
- `fvm dart format` does NOT add a trailing comma if missing — that's the lint's job.
- `fvm dart format` may strip a trailing comma from a single-line construct.
- Workflow: format first to settle line breaks, then `dart fix --apply --code=require_trailing_commas`.

## See also

- `docs/02-conventions.md` § Trailing commas
- `analysis_options.yaml` — `require_trailing_commas: true`
- `.claude/rules/import-rules.md` — companion formatting rule

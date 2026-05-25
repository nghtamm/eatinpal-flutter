---
name: import-rules
description: Imports ordered dart → package → relative, sorted, no unused. Cross-module imports go through the target module's barrel; core files are imported individually. Trim + reorder on every file edit.
---

# Rule: Import rules

## Constraint

### Import order

Group imports in this order, separated by blank lines:

1. `dart:` imports
2. `package:` imports
3. Local imports (relative paths starting with `..` or no prefix)

Within each group, sort alphabetically.

### Optimise on every edit

Before saving a file you touched:

1. **Trim unused** — remove every `import` whose symbols aren't referenced. `fvm flutter analyze` reports them as `unused_import`; treat as errors.
2. **Reorder** — apply the three-group rule above.
3. **Merge duplicates** — only one `import` per package per file.
4. **Prefer full imports** — `import 'package:foo/foo.dart';` over `show` / `hide`. Use `as` aliases only to resolve a real symbol clash.

`fvm dart fix --apply` auto-clears some unused imports. For reordering use the IDE's "Optimize Imports" command.

### Layering

| Source | Target | Allowed? |
|---|---|---|
| `lib/modules/<m>/*` | `lib/core/*` (individual files) | ✅ |
| `lib/modules/<m>/*` | another module's barrel `lib/modules/<other>/<other>.dart` | ⚠ allowed but discouraged — see `.claude/rules/modular-structure.md` |
| `lib/modules/<m>/*` | files inside another module (not barrel) | ❌ FORBIDDEN |
| `lib/core/*` | `lib/core/*` (where it makes sense) | ✅ |
| `lib/core/*` | `lib/modules/*` | ❌ FORBIDDEN — except `lib/app/router/app_router.dart` (composition root) |
| `lib/main.dart` / `lib/app/app.dart` | both `core/` and `modules/<m>/<m>.dart` | ✅ |

### Barrel rule

Each module ships ONE barrel: `lib/modules/<name>/<name>.dart`. Cross-module consumers import that barrel — never individual files from another module. Within the same module, prefer relative imports (don't import your own barrel; risks circular re-exports).

`core/` does NOT have a barrel — import individual files directly.

## Why

- **Predictable order** makes diffs cleaner.
- **Layered imports** make dependency direction explicit — `modules → core`.
- **Barrel rule** keeps module surfaces minimal and refactor-safe.
- **`dart:` first** matches the Dart team's style.

## Examples

### ✅ Correct

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
import 'package:eatinpal/modules/auth/auth.dart';
```

### ❌ Incorrect — mixed ordering

```dart
import '../bloc/auth_bloc.dart';                       // ❌ relative before package
import 'package:flutter/material.dart';
import 'dart:async';                                   // ❌ dart in middle
import 'package:flutter_bloc/flutter_bloc.dart';
```

### ❌ Incorrect — cross-module file import (not barrel)

```dart
// In lib/modules/profile/presentation/pages/profile_page.dart
import 'package:eatinpal/modules/auth/presentation/bloc/auth_bloc.dart';   // ❌
// → import 'package:eatinpal/modules/auth/auth.dart';                     // ✅
```

### ❌ Incorrect — `core` importing a module

```dart
// In lib/core/widgets/app_button.dart
import 'package:eatinpal/modules/auth/auth.dart';                          // ❌
```

If `core` truly needs something from a module, that something belongs in `core` — extract it.

### ✅ Correct — composition root may import any module

```dart
// In lib/app/router/app_router.dart
import 'package:eatinpal/modules/auth/auth.dart';                          // ✅
import 'package:eatinpal/modules/onboarding/onboarding.dart';              // ✅
```

`app_router.dart` is the composition root for routing — it's the one `core/`-adjacent file allowed to import modules.

### ✅ Correct — within the same module, prefer relative imports

```dart
// In lib/modules/auth/presentation/bloc/auth_bloc.dart
import '../../domain/usecases/login_usecase.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
```

Don't import `package:eatinpal/modules/auth/auth.dart` from within `lib/modules/auth/` — circular re-export risk.

## Tooling notes

- `fvm dart format` does NOT reorder imports — only whitespace.
- `fvm dart fix --apply` clears some unused imports.
- IDE "Optimize Imports" reorders + trims in one step.
- `fvm flutter analyze` reports `unused_import` warnings — treat as hard errors.

## See also

- `docs/02-conventions.md` § Imports — full narrative
- `docs/01-architecture.md` § Layering — rationale
- `.claude/rules/modular-structure.md` — cross-module rule

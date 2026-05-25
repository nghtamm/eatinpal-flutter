---
name: shared-defs
description: Before declaring a const, typedef, enum, or raw UI primitive, check `lib/core/constants/` and `lib/core/helpers/` first. Reuse AppColors, AppSpacing/AppPadding/AppRadius, AppTypography, SIZED_BOX constants. Surface missing tokens — never hard-code raw primitives.
---

# Rule: Shared definitions

## Constraint

Before declaring a new constant, typedef, cross-module enum, or any raw UI primitive, check `lib/core/` first.

**Code definitions** — check `lib/core/constants/` and `lib/core/helpers/`.

**UI primitives** — check `lib/core/constants/`:

- `lib/core/constants/app_colors.dart` — `AppColors` (all color constants, `UPPER_SNAKE_CASE`)
- `lib/core/constants/app_spacing.dart` — `AppPadding`, `AppRadius`, plus `SIZED_BOX_H4/H8/H12/H16/H20/H24/H32/H40` and `SIZED_BOX_W4/W8/W12` gap spacers
- `lib/core/constants/app_typography.dart` — `AppTypography` (text style constants)
- `lib/core/constants/app_theme.dart` — `AppTheme` (ThemeData)

**Cross-cutting modules** — check `lib/core/`:

- `lib/core/network/api_endpoints.dart` — `ApiEndpoints` constants (path strings)
- `lib/core/network/exceptions.dart` — `AppException` and subtypes
- `lib/app/router/route_names.dart` — `RoutePaths`, `RouteNames`
- `lib/core/local/local_storage.dart` — keys live as `static const _UPPER_SNAKE_CASE` inside `LocalStorageImpl`
- `lib/core/helpers/` — extensions, validators (`Validators`), JWT utilities

**Shared widgets** — check `lib/core/widgets/`:

- `AppButton` (with `AppButtonVariant.SECONDARY` etc.)
- `AppSnackbar` (`success`/`info`/`warning`/`error` with `AppSnackbarType` enum)
- `BasicAppBar`, `LoadingOverlay`, `AppCircularProgress`

**Use what's there.** Never duplicate or re-declare a value that already exists in `core/`.

**Promote when scope is wider than one file.** If a value is referenced from more than one file — or its meaning is app-wide — declare it in the appropriate `core/` file, not inline.

Keep inline ONLY when scope is genuinely a single file AND the symbol is private (`_LOCAL_THING`).

### Raw primitive rule — principle-level

Any Flutter/Dart primitive whose value carries a *design decision* — layout, spacing, color, radius, typography, animation duration, opacity, curve, elevation — MUST come from a `core/constants/` token.

**Mental test** — apply every time you're about to type a Flutter primitive value:

1. **Would this value plausibly change if the design changed?** Spacing, color, radius, font size, transition duration, elevation. → YES → must come from a token. No exceptions.
2. **Is it a "neutral / convenience" form?** `EdgeInsets.zero`, `BorderRadius.zero`, `Colors.transparent`, `SizedBox.shrink()`, `Duration.zero`, `Curves.linear`, `Alignment.center`. → STILL must come from a token. These are *design decisions at the zero/neutral point* of the scale.
3. **Is it a non-design value** (HTTP timeout `Duration`, business-logic threshold)? → Belongs in an app-wide constant or scoped class, still centralised.
4. **Is the value genuinely private** to one file AND not design-relevant (e.g., a regex anchor only this validator uses)? → Inline `static const _NAME` is allowed.
5. **Is it a widget-internal layout primitive** (container size, stroke width, connector dimension, painter canvas size) used in ONE widget for ONE visual purpose? → Inline `static const _NAME` (private to the State class or top of the file) is allowed. Promote to `core/` ONLY if the same primitive value/shape appears in ≥ 2 files.

**Decision flow** (no fallback path):

- Token exists in `core/constants/` → use it.
- Token doesn't exist → STOP. Surface the gap with a proposed token name + location. Wait for user approval before inlining.
- **EXCEPTION** — if the value satisfies test #5 (widget-internal, single visual purpose, file-local), declare as private `static const _NAME` directly without surfacing.
- Never inline a raw design primitive — not even temporarily, not even as a `// TODO`.

Example surface prompt:

> "Need `EdgeInsets.zero` for [X]. `AppPadding` doesn't have `NONE` yet. Propose `static const NONE = 0.0;` (and `EdgeInsets.zero` is `EdgeInsets.fromLTRB(AppPadding.NONE, ...)`). Approve?"

### What goes where

| Symbol | Home |
|---|---|
| App-wide duration / size / count / limit | `lib/core/constants/` (add a new `*.dart` if needed) |
| Spacing / padding scalar | `AppPadding` in `app_spacing.dart` |
| Border-radius constant | `AppRadius` in `app_spacing.dart` |
| Gap `SizedBox` (vertical/horizontal) | `SIZED_BOX_H*` / `SIZED_BOX_W*` in `app_spacing.dart` |
| Color constant | `AppColors` in `app_colors.dart` |
| Text style constant | `AppTypography` in `app_typography.dart` |
| Storage key | `static const _UPPER_SNAKE_CASE` private to `LocalStorageImpl` in `local_storage.dart` |
| Route path / name | `RoutePaths` / `RouteNames` in `app/router/route_names.dart` |
| API path | `ApiEndpoints` in `core/network/api_endpoints.dart` |
| Shared widget used in ≥ 2 modules | `lib/core/widgets/` |
| Module-private widget | `lib/modules/<m>/presentation/widgets/` |
| Cross-module typedef / enum | `lib/core/helpers/` or a dedicated `lib/core/types.dart` (discuss before adding the file) |
| Private-to-file magic number (non-design) | Inline `static const _NAME` (private) |
| Widget-internal layout primitive (single widget, single purpose) | Inline `static const _NAME` private to widget/file |

## Why

- One source of truth — tweaking `AppColors.PRIMARY` or `AppPadding.LG` is a one-line change.
- AI agents and humans both grep `core/constants/` first; scattered declarations defeat that.
- Inline magic numbers are a refactor trap — first reuse silently copy-pastes the literal.
- Raw UI literals scattered across views make a theme tweak a grep exercise; tokens make it a one-file edit.
- Consistent token usage is a prerequisite for reliable responsive / accessibility scaling.

## Examples

### ✅ Correct — reuse spacing constants

```dart
return Padding(
  padding: const EdgeInsets.fromLTRB(
    AppPadding.XL,
    AppPadding.LG,
    AppPadding.XL,
    AppPadding.NONE,
  ),
  child: Column(
    children: [
      _title(),
      SIZED_BOX_H12,
      _subtitle(),
      SIZED_BOX_H32,
      AppButton(label: 'LOGIN', onPressed: _submit, height: 56),
    ],
  ),
);
```

### ❌ Incorrect — raw `EdgeInsets` / `SizedBox` literals

```dart
return Padding(
  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),    // ❌ use AppPadding.*
  child: Column(
    children: [
      _title(),
      const SizedBox(height: 12),                       // ❌ use SIZED_BOX_H12
      _subtitle(),
    ],
  ),
);
```

### ✅ Correct — `AppColors` / `AppTypography`

```dart
Text(
  'WELCOME\nBACK',
  style: AppTypography.DISPLAY_LARGE.copyWith(
    fontSize: 44,
    color: AppColors.NEUTRAL_10,
  ),
)
```

### ❌ Incorrect — hard-coded color / text style

```dart
Text(
  'WELCOME\nBACK',
  style: TextStyle(
    color: Color(0xFF111827),                           // ❌ use AppColors.NEUTRAL_10
    fontSize: 44,
    fontWeight: FontWeight.bold,
  ),
)
```

### ✅ Correct — file-local private constant (kept inline)

```dart
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');   // ✅ private, validator-only
}
```

### ❌ Incorrect — magic number with app-wide reach

```dart
class FoodListBloc {
  static const _pageSize = 20;                            // ❌ if shared across modules, promote
}
```

## Decision flow

When you're about to write a `const`, `static const`, `typedef`, or any raw UI primitive:

1. **Is it a UI primitive** (`EdgeInsets`, `BorderRadius`, `Color`, `TextStyle`, `SizedBox` literal)?
   - Look in `lib/core/constants/`.
   - Token exists → use it. No token → ask user before adding; never hard-code inline.
2. **Is it a code-level constant or typedef?** Look in `lib/core/` — already there? → use it.
3. **Is it private to this file AND will stay that way?** → declare inline with `_` prefix.
4. **Otherwise** → add to the appropriate `core/` file and import.

When you spot an inline literal that meets criterion 1 or 4 during a refactor, promote it.

## Naming reminder

- `AppColors` / `AppPadding` / `AppRadius` / `AppTypography` fields → `UPPER_SNAKE_CASE`
- `SIZED_BOX_H*` / `SIZED_BOX_W*` → top-level `UPPER_SNAKE_CASE`
- Typedefs → `PascalCase`
- Inline private constants → `_UPPER_SNAKE_CASE`

See `.claude/rules/naming-conventions.md` for the full table.

## See also

- `docs/07-theming-ui.md` — design tokens narrative + decision flow
- `lib/core/constants/app_colors.dart` — `AppColors`
- `lib/core/constants/app_spacing.dart` — `AppPadding`, `AppRadius`, `SIZED_BOX_*`
- `lib/core/constants/app_typography.dart` — `AppTypography`
- `lib/core/widgets/` — shared widgets to reuse instead of recreating
- `.claude/rules/naming-conventions.md` — casing rules

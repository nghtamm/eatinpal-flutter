---
name: responsive-ui
description: Use when a screen must adapt to varied widths (small phones to tablets), notch/status-bar / safe area, keyboard insets, orientation. Covers `MediaQuery`, `SafeArea`, `LayoutBuilder`, `OrientationBuilder`, breakpoint patterns, keyboard avoidance.
---

# Skill: Responsive UI

## When to use

Designing or fixing a screen that:

- Looks broken on narrow phones (< 360 dp) — overlapping text / clipped buttons.
- Wastes space on tablets (single column stretched to 1024 dp).
- Hides content behind notch / status bar / home indicator.
- Pushes content off-screen when the keyboard opens.
- Should respond to landscape rotation.

Concrete reference: `lib/modules/auth/presentation/pages/authentication_page.dart` — uses `MediaQuery.padding.top` to extend banner into safe area while keeping content sheet within it.

## Layers

| Concern | API |
|---|---|
| Safe area (notch, home indicator) | `SafeArea` widget OR `MediaQuery.of(context).padding` |
| Keyboard insets | `MediaQuery.of(context).viewInsets.bottom` OR `Scaffold(resizeToAvoidBottomInset: true)` (default) |
| Total size | `MediaQuery.of(context).size` |
| Constraint-driven | `LayoutBuilder(builder: (ctx, constraints) => …)` |
| Orientation | `OrientationBuilder` OR `MediaQuery.of(context).orientation` |

## Patterns

### Safe area — banner that extends to top, content sheet within

```dart
final inset = MediaQuery.of(context).padding.top;
final bannerHeight = _BANNER_HEIGHT + inset;

return Scaffold(
  body: Stack(
    children: [
      Positioned(top: 0, left: 0, right: 0, height: bannerHeight, child: _banner(inset)),
      Positioned(
        top: bannerHeight - _SHEET_OVERLAP,
        bottom: 0, left: 0, right: 0,
        child: _content(),
      ),
    ],
  ),
);
```

When you do NOT want extending: wrap with `SafeArea` (default: insets all 4 sides).

### Keyboard avoidance

`Scaffold(resizeToAvoidBottomInset: true)` (default) shrinks the body when keyboard opens. Wrap form content in `SingleChildScrollView` so it scrolls instead of overflowing:

```dart
Scaffold(
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        children: [
          AuthTextField(...),
          SIZED_BOX_H20,
          AuthTextField(...),
        ],
      ),
    ),
  ),
)
```

For full-screen pages with a fixed bottom button (login submit), use a `Column` with `Expanded` body + bottom button outside the scroll:

```dart
SafeArea(
  child: Column(
    children: [
      Expanded(child: SingleChildScrollView(child: _form())),
      Padding(
        padding: const EdgeInsets.all(AppPadding.XL),
        child: AppButton(label: 'SUBMIT', onPressed: _submit, height: 56),
      ),
    ],
  ),
)
```

`Scaffold` will lift the bottom button above the keyboard automatically.

### `LayoutBuilder` for constraint-driven layout

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth > 600;
    return isWide
      ? Row(children: [Expanded(child: _sidebar()), Expanded(flex: 2, child: _content())])
      : Column(children: [_sidebar(), _content()]);
  },
)
```

Prefer constraint-driven over `MediaQuery.size.width` when only this widget's available width matters (e.g., inside a card). Use `MediaQuery` only for genuinely screen-wide decisions.

### Breakpoints

For multi-form-factor apps (rare in EatinPal — mobile-only):

```dart
abstract final class Breakpoints {
  static const PHONE = 600.0;
  static const TABLET = 900.0;
  static const DESKTOP = 1200.0;
}
```

Add to `lib/core/constants/` if needed. Surface BEFORE adding (per `.claude/rules/shared-defs.md`).

### Orientation handling

For a mobile app, locking portrait at app-launch is common:

```dart
// In main.dart, after WidgetsFlutterBinding.ensureInitialized
import 'package:flutter/services.dart';
await SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
]);
```

EatinPal's `main.dart` currently sets `SystemUiOverlayStyle` for status bar — orientation lock could go beside it (surface before adding).

For per-screen orientation handling without locking globally:

```dart
OrientationBuilder(
  builder: (context, orientation) {
    return orientation == Orientation.portrait
      ? _portraitLayout()
      : _landscapeLayout();
  },
)
```

### Text overflow

```dart
Text(
  veryLongName,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: AppTypography.BODY_MEDIUM,
)
```

`Expanded` / `Flexible` in a `Row` so the `Text` can shrink:

```dart
Row(
  children: [
    const Icon(Icons.person),
    SIZED_BOX_W8,
    Expanded(
      child: Text(
        user.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.BODY_MEDIUM,
      ),
    ),
  ],
)
```

Without `Expanded`, the text tries to take its intrinsic width and overflows.

## Common pitfalls

- **Reading `MediaQuery` inside `initState`** — no `BuildContext` available with inherited widgets resolved. Use `WidgetsBinding.instance.addPostFrameCallback`.
- **`SafeArea` inside an already-safe parent** — double-padding. Use only at the outermost layer of a screen.
- **`SizedBox` with raw height for "spacing for safe area"** — use `MediaQuery.padding.top` instead so it adapts per device.
- **`Stack` + `Positioned(top: 0)` without thinking about notch** — content disappears behind it.
- **Fixed `height` on a card with variable content** — clips on small screens.
- **`Row` with multiple `Text` children — no `Expanded`** — first text overflows.
- **Hard-coded `MediaQuery.size.width / 2`** — assumes screen width matters, ignores siblings.

## See also

- `docs/07-theming-ui.md` § Responsive — full narrative
- `lib/modules/auth/presentation/pages/authentication_page.dart` — banner + sheet pattern
- `.claude/skills/a11y-patterns/SKILL.md` — text scaling considerations
- `.claude/skills/ui-states/SKILL.md` — empty/error UI on small screens
- Flutter responsive docs: <https://docs.flutter.dev/ui/adaptive-responsive>

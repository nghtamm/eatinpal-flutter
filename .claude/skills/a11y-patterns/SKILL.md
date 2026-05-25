---
name: a11y-patterns
description: Use when reviewing or building UI for accessibility — `Semantics` labels on icons/image buttons, ≥ 48 dp tap targets, contrast via `AppColors`, focus order, screen-reader announcements for BLoC state changes, RTL/LTR direction, large-text scaling, dialog/modal a11y.
---

# Skill: Accessibility patterns

## When to use

Every UI build or review. A11y is not optional polish.

## Quick audit checklist

- [ ] **Tap target ≥ 48 dp** in any direction. Wrap small icons in `IconButton` or `InkWell` with explicit padding.
- [ ] **Icon-only buttons have `Semantics(label: ...)`** or `tooltip:`. Otherwise screen readers say "button" with no context.
- [ ] **Image / `GestureDetector` buttons have `Semantics(button: true, label: ...)`** — invisible to screen readers without it.
- [ ] **Form fields have `InputDecoration(labelText: ...)`** — provides visible + accessible label.
- [ ] **Text uses tokens** (`AppTypography.*`, `AppColors.*`) — guarantees theme-defined contrast.
- [ ] **Large-text scales gracefully** — test with system font size at 200%. No clipped text.
- [ ] **State changes announce** — when a BLoC transitions to loaded/error, use `Semantics(liveRegion: true)` or `SemanticsService.announce(...)`.
- [ ] **Dialog a11y** — `showDialog` adds focus trap by default. Don't override unless you re-implement.
- [ ] **RTL works** — use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`.

## Patterns

### Icon-only button

```dart
// ❌ Screen-reader hears "Button". No context.
IconButton(icon: Icon(Icons.edit), onPressed: _onEdit)

// ✅ With tooltip → tooltip also serves as a11y label.
IconButton(
  icon: const Icon(Icons.edit),
  tooltip: 'Edit profile',
  onPressed: _onEdit,
)

// ✅ Image button — `Semantics` mandatory.
Semantics(
  button: true,
  label: 'Profile image',
  child: GestureDetector(
    onTap: _onAvatarTap,
    child: ClipOval(child: Image.network(url)),
  ),
)
```

### Tap target enlargement

```dart
// ❌ 24×24 hit target.
Icon(Icons.close, size: 24)

// ✅ Wrap with InkWell + padding to reach 48dp.
Material(
  type: MaterialType.transparency,
  child: InkWell(
    customBorder: const CircleBorder(),
    onTap: _onClose,
    child: const Padding(
      padding: EdgeInsets.all(AppPadding.MD),    // 24 + 12+12 = 48
      child: Icon(Icons.close, size: 24),
    ),
  ),
)
```

### Live regions / announcements for BLoC state

```dart
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
  builder: (_, state) => Semantics(
    liveRegion: true,
    child: Text(
      state is AuthLoading ? 'Signing in…' : 'Ready',
      style: AppTypography.BODY_MEDIUM,
    ),
  ),
);

// One-off announcement (after submit success/error)
import 'package:flutter/semantics.dart';

SemanticsService.announce('Saved.', TextDirection.ltr);
```

Only announce meaningful changes — load result, submit outcome. Decorative animation should NOT trigger announcements.

### RTL / direction-aware layout

```dart
// ❌ Hardcoded direction.
padding: const EdgeInsets.only(left: AppPadding.LG),

// ✅ Directional.
padding: const EdgeInsetsDirectional.only(start: AppPadding.LG),
```

Same for `Positioned.directional`, `BorderRadiusDirectional`. `Row` auto-flips under `Directionality`.

### Text scaling

Use `AppTypography.*` — scales via system text size. Avoid inline `TextStyle(fontSize: ...)`.

If a layout MUST stay compact (badge with a number), clamp at the widget level:

```dart
MediaQuery.withClampedTextScaling(
  maxScaleFactor: 1.2,
  child: const _Badge(),
)
```

Use sparingly.

### Contrast

Use `AppColors.*` — design system pre-validated for WCAG AA. Don't invent low-contrast variants. If a design ships with text below 4.5:1 contrast (body) or 3:1 (large text), surface BEFORE implementing.

## Common pitfalls

- Icon button without label/tooltip → screen reader says "Button".
- `GestureDetector` on text/image without `Semantics` → invisible to screen readers.
- Inline `EdgeInsets.only(left: ...)` → flips wrong in RTL.
- Inline `TextStyle(fontSize: ...)` → ignores text scaling.
- Tap target ≤ 32 dp → fails motor accessibility.
- Announcing every state change → noisy; users disable.
- Color-only state indication → color-blind users miss it; pair with icon/text.
- `LoadingOverlay` shown without `Semantics(liveRegion: true, label: 'Loading')` wrapper → screen reader hears silence.

## How to test

- **iOS Simulator:** Settings → Accessibility → VoiceOver. Triple-click home.
- **Android Emulator:** Settings → Accessibility → TalkBack.
- **Text scaling:** Settings → Display → Font size → Largest.
- **RTL:** wrap widget in `Directionality(textDirection: TextDirection.rtl, child: ...)`.
- **Contrast:** use the tokens — pre-validated.

## See also

- `docs/07-theming-ui.md` § Accessibility — full narrative
- `lib/core/constants/app_colors.dart`, `app_typography.dart` — pre-validated tokens
- `.claude/skills/animations/SKILL.md` — `disableAnimationsOf` reminder
- `.claude/skills/form-handling/SKILL.md` — `InputDecoration.labelText` for form a11y
- Flutter docs: <https://docs.flutter.dev/ui/accessibility>

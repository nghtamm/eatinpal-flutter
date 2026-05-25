---
name: animations
description: Use when adding any animation to UI — page transitions, micro-interactions, list-item enter/exit, hero shared-element, parallax, skeletons. Decision tree for implicit (AnimatedContainer / AnimatedOpacity) vs explicit (AnimationController) vs hero, plus go_router page transition customisation.
---

# Skill: Animations

## When to use

Adding motion to UI. Categories:

- Micro-interaction (button press, toggle, focus highlight)
- State transition (loading → loaded, expanded ↔ collapsed)
- List entry / exit (`AnimatedList`, `AnimatedSwitcher`)
- Page-level transition (`go_router` `pageBuilder`)
- Hero shared-element across routes
- Decorative parallax / scroll-driven

Concrete reference: `lib/modules/auth/presentation/pages/verification_success_page.dart` — intricate arc + halo + particles + check animation built from `AnimationController` + `CustomPainter`.

## Pick the right API

| Need | API |
|---|---|
| Animate one or two properties tied to state | **Implicit** — `AnimatedContainer`, `AnimatedOpacity`, `AnimatedAlign`, `AnimatedPadding`, `TweenAnimationBuilder` |
| Multiple coordinated values, custom curve, repeat | **Explicit** — `AnimationController` + `Tween` + `AnimatedBuilder` |
| Swap one widget for another with fade/slide | `AnimatedSwitcher` |
| Animate list items entering/leaving | `AnimatedList` / `SliverAnimatedList` |
| Share element across routes | `Hero(tag: ...)` on both screens |
| Customize page transition | `go_router` `pageBuilder` returning `CustomTransitionPage` |
| Scroll-linked effect (parallax) | `ScrollController` + `AnimatedBuilder` |

When in doubt: try implicit first. Explicit ONLY when implicit can't express the animation.

## Implicit example

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeOutCubic,
  padding: expanded ? const EdgeInsets.all(AppPadding.XL) : const EdgeInsets.all(AppPadding.MD),
  decoration: BoxDecoration(
    color: expanded ? AppColors.PRIMARY_SOFT : AppColors.SURFACE,
    borderRadius: BorderRadius.circular(AppRadius.BASE),
  ),
  child: const _Content(),
)
```

## Explicit example

```dart
class _PulseLogo extends StatefulWidget {
  const _PulseLogo();
  @override State<_PulseLogo> createState() => _PulseLogoState();
}

class _PulseLogoState extends State<_PulseLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();             // CRITICAL — leaks otherwise
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (ctx, child) => Transform.scale(scale: _scale.value, child: child),
      child: const _Logo(),
    );
  }
}
```

`AnimatedBuilder` rebuilds only its `builder` — pass static child as `child:` to avoid rebuilding it. For multiple controllers, merge via `Listenable.merge([a, b])`.

## Hero shared-element

```dart
// Source
Hero(tag: 'food-${food.id}', child: Image.network(food.imageUrl))

// Detail — same tag
Hero(tag: 'food-${food.id}', child: Image.network(food.imageUrl))
```

`go_router` supports hero transitions out of the box. Tags must match per-element and be unique per page (use the ID). Avoid hero on widgets with state — they flicker.

## go_router custom page transition

```dart
GoRoute(
  path: RoutePaths.MODAL_SHEET,
  name: RouteNames.MODAL_SHEET,
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const SomeModalPage(),
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (ctx, animation, _, child) {
      return SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      );
    },
  ),
),
```

Reserve custom transitions for genuinely modal routes (sheets, full-screen cover). Stick with default platform transitions otherwise.

## Duration + curve recipes

| Effect | Duration | Curve |
|---|---|---|
| Button press / focus | 100 ms | `Curves.easeOut` |
| Toggle / small UI change | 200–250 ms | `Curves.easeOutCubic` |
| Page transition | 300 ms | `Curves.easeOutCubic` |
| Bottom sheet enter | 250 ms | `Curves.easeOutCubic` |
| Hero | 350 ms (Flutter default) | `Curves.fastOutSlowIn` |
| Skeleton shimmer | 1500 ms loop | linear |

Reduce-motion: respect `MediaQuery.disableAnimationsOf(context)` — if true, set `Duration.zero` or skip the animation:

```dart
final duration = MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 250);
```

System a11y setting; ignoring it is an accessibility fail.

## Common pitfalls

- **Missing `_controller.dispose()`** — battery + memory leak.
- **Animating in a `Stateless` widget** — controllers require state. Use `StatefulWidget`.
- **`AnimatedBuilder` rebuilding heavy child** — pass child as `child:` parameter, not inside the closure.
- **Hero with non-unique tag** — flickers / wrong element jumps.
- **Custom transition on every route** — feels off-platform.
- **Ignoring `disableAnimationsOf`** — fails motion-sensitivity a11y.
- **Looping animation never stops** — drains battery; pause when not visible.

## See also

- `docs/07-theming-ui.md` § Animations — full narrative
- `docs/09-performance.md` § Animation performance
- `lib/modules/auth/presentation/pages/verification_success_page.dart` — multi-controller `CustomPainter` reference
- `.claude/skills/a11y-patterns/SKILL.md` — `disableAnimationsOf` reminder
- Flutter docs: <https://docs.flutter.dev/ui/animations>

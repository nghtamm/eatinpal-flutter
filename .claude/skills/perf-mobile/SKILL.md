---
name: perf-mobile
description: Use when the app feels janky / a screen rebuilds too often / a list scrolls poorly. Covers `const` constructors, `ListView.builder`, `RepaintBoundary`, BLoC `buildWhen` selectors, image sizing, `AnimatedBuilder.child`, `RouteAware` pause-on-leave, profile-mode measurement.
---

# Skill: Mobile performance

## When to use

- A page rebuilds on every keystroke / unrelated state change.
- A list scrolls poorly past ~50 items.
- An animation drops frames.
- An image-heavy page lags on first paint.

## Profile FIRST

Always measure before optimizing. `fvm flutter run --profile` + DevTools "Performance" tab shows the actual jank. Optimizing without profiling is voodoo.

## Patterns

### 1. `const` constructors

Every widget literal that can be `const` should be `const`. The Flutter framework reuses const widgets and skips rebuilding them.

```dart
// ❌
return Column(children: [
  Text('Hello'),
  SizedBox(height: 8),
]);

// ✅
return const Column(children: [
  Text('Hello'),
  SizedBox(height: 8),
]);
```

When you can't make the parent const but a child can be, wrap the const child explicitly:

```dart
return Column(children: [
  Text(user.name),
  const SizedBox(height: 8),    // ✅ child stays const
]);
```

### 2. `ListView.builder` for any list > ~10 items

`ListView(children: [...])` builds and lays out every child up front. `ListView.builder` lazy-builds visible items.

```dart
// ❌ Builds 1000 widgets at mount.
ListView(children: items.map((i) => _ItemCard(item: i)).toList())

// ✅ Builds visible + a few prefetched.
ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, i) => _ItemCard(item: items[i]),
)
```

For known-small static lists (≤10 items), `Column` is fine and avoids the `ListView` overhead.

### 3. `BlocBuilder.buildWhen` to scope rebuilds

Default `BlocBuilder` rebuilds on every state emit. For perf-sensitive UI, scope:

```dart
return BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (prev, curr) => (prev is AuthLoading) != (curr is AuthLoading),
  builder: (_, state) => LoadingOverlay(
    isLoading: state is AuthLoading,
    child: /* ... */,
  ),
);
```

`BlocListener` for side effects (snackbar, navigation) — no rebuilds.

Use `BlocSelector<Bloc, State, T>` when only a single field of the state matters.

### 4. `RepaintBoundary` to isolate repaints

Wrap a widget that repaints often (animation) so it doesn't dirty its parent:

```dart
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _controller,
    builder: (_, _) => CustomPaint(painter: _ArcPainter(progress: _controller.value)),
  ),
)
```

Use sparingly — each `RepaintBoundary` allocates a layer. Profile to confirm it helps.

### 5. `AnimatedBuilder.child` to skip rebuilding static children

```dart
AnimatedBuilder(
  animation: _scale,
  builder: (ctx, child) => Transform.scale(scale: _scale.value, child: child),
  child: const _Logo(),     // ← built ONCE, never rebuilt
)
```

If `_Logo()` were inside the `builder` closure, it'd rebuild every animation tick.

### 6. Image sizing

Always provide `cacheWidth` / `cacheHeight` (or `width` / `height`) to network/asset images. Otherwise Flutter caches the full-resolution image (often a 4MB decoded bitmap for a thumbnail).

```dart
Image.network(
  url,
  cacheWidth: 240,                  // ← match render size, not source size
  cacheHeight: 240,
  fit: BoxFit.cover,
)
```

For SVG, use `flutter_svg` (not in pubspec by default — surface before adding).

### 7. Avoid rebuilding the whole tree on text input

`TextEditingController` notifies on every keystroke. If a widget that doesn't care about the text value listens (via `Provider`/inherited), it rebuilds. Confine the listener to the smallest possible subtree — e.g., `TextField` itself.

### 8. `RouteAware` to pause expensive work when off-screen

A page that runs a `Timer.periodic` or polls should pause when the user navigates away. Use `RouteObserver` + `RouteAware`:

```dart
class _MyPageState extends State<MyPage> with RouteAware {
  @override
  void didPushNext() => _timer?.cancel();  // user pushed something on top
  @override
  void didPopNext() => _startTimer();      // user came back
}
```

EatinPal doesn't wire a `RouteObserver` by default — surface if needed.

### 9. `addPostFrameCallback` for one-shot post-build work

Don't do work that touches `BuildContext` during `initState`:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _doSomething());
}
```

### 10. Avoid `dynamic` in hot paths

`dynamic` defeats compiler optimizations. Type explicitly even when verbose.

## Measure with DevTools

```bash
fvm flutter run --profile
```

- **Performance** tab: see per-frame breakdown. Frame > 16ms = jank.
- **CPU profiler**: which function eats time.
- **Memory**: find leaks. After navigating around, force GC and check if widgets/state objects accumulate.
- **Widget inspector → Track widget rebuilds**: see what rebuilds per frame.

## Common pitfalls

- **`SizedBox(height: 8)` not const** — small win × many places = real.
- **`ListView(children: [...])` for long list** — builds all children up front.
- **Default `BlocBuilder` everywhere** — every state emit rebuilds the whole subtree.
- **`Image.network` with no cache size** — decoded to full source resolution.
- **`AnimatedBuilder` rebuilding heavy child** — pass child as `child:` parameter.
- **Animation controller not disposed** — battery drain.
- **`setState` in a parent that re-mounts a heavy subtree** — extract subtree, lift state up only as much as needed.

## See also

- `docs/09-performance.md` — full perf checklist + decisions
- `.claude/skills/animations/SKILL.md` — `AnimatedBuilder.child` discipline
- `lib/modules/auth/presentation/pages/verification_success_page.dart` — multi-controller example (note: `_arcController` + `_haloController` merged via `Listenable.merge` for the drift)
- Flutter perf docs: <https://docs.flutter.dev/perf>

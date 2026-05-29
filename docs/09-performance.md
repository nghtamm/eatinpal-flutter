# Performance

Mobile performance checklist + decisions. Most of these are micro-budgets (each costs a few % of frame time) but stack to the difference between "smooth" and "janky" perception. EatinPal targets Android + iOS only — desktop / web compromises don't apply.

## The 60 fps budget

| Frame budget | Per frame |
|---|---|
| 60 fps | 16.6 ms (~16 ms practical) |
| 120 fps (recent phones) | 8.3 ms |

Of that, Flutter spends ~4-8 ms on rasterization / GPU. The Dart UI thread has the rest (~8-12 ms) to:

- Run `build()` for changed widgets.
- Run layout + paint for changed render objects.
- Process gestures, animations, BLoC emissions.

Anything blocking the UI thread for more than ~16 ms is a dropped frame. JSON decode of a 200 KB list, large image decode, synchronous file I/O — all common offenders.

## `const` everywhere possible

`const` constructors create canonical, immutable widget instances. Flutter's diffing short-circuits when it sees the same `const` instance — no rebuild, no `==` check, no layout pass.

```dart
// ❌
Padding(padding: EdgeInsets.all(AppPadding.BASE), child: Text('hi'))

// ✅ Both const
const Padding(padding: EdgeInsets.all(AppPadding.BASE), child: Text('hi'))
```

Rules:

- Mark every leaf widget you can as `const`. The Dart linter (`prefer_const_constructors`) flags missing ones — treat warnings as errors.
- Token classes (`AppPadding.BASE`, `SIZED_BOX_H16`, `AppColors.PRIMARY`) are already `const`-compatible — using them lets widgets be `const`.
- `BlocProvider(create: (_) => di<...>(), child: const ChildWidget())` — make the child `const` so it's not rebuilt when the BLoC re-emits.

## Reactive granularity — scope `BlocBuilder` / `Obx`-equivalents narrowly

Wrapping the whole `body` in a single `BlocBuilder` makes every emission rebuild every widget. Scope tightly.

### Use `buildWhen` to filter

Real example from `LoginPage`:

```dart
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (prev, curr) => (prev is AuthLoading) != (curr is AuthLoading),
  builder: (_, state) => LoadingOverlay(
    isLoading: state is AuthLoading,
    child: Scaffold(...),
  ),
)
```

Only rebuilds when the `AuthLoading` ↔ non-`AuthLoading` transition happens. Intermediate emissions (`AuthInitial → AuthLoading → AuthAuthenticated`) trigger one rebuild each instead of an unrelated three.

### Split `BlocBuilder` per concern

```dart
Column(
  children: [
    BlocBuilder<FoodListBloc, FoodListState>(
      buildWhen: (p, c) => p.status != c.status,
      builder: (_, s) => _statusBanner(s.status),
    ),
    Expanded(
      child: BlocBuilder<FoodListBloc, FoodListState>(
        buildWhen: (p, c) => p.items != c.items,    // list identity check
        builder: (_, s) => _listView(s.items),
      ),
    ),
  ],
)
```

Each `BlocBuilder` rebuilds only when its `buildWhen` returns `true`.

### Pull invariant subtrees out of the builder

```dart
// ❌ App bar rebuilds every state emission
BlocBuilder<FoodListBloc, FoodListState>(
  builder: (_, state) => Scaffold(
    appBar: const BasicAppBar(title: Text('Foods')),
    body: _content(state),
  ),
)

// ✅ App bar is `const`, never rebuilt
Scaffold(
  appBar: const BasicAppBar(title: Text('Foods')),
  body: BlocBuilder<FoodListBloc, FoodListState>(
    builder: (_, state) => _content(state),
  ),
)
```

### `BlocListener` for side-effects (no rebuild)

If a state emission only needs to fire a snackbar / navigation — NOT rebuild UI — use `BlocListener`, not `BlocConsumer`. `BlocListener` doesn't rebuild on every emission.

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (ctx, state) {
    if (state is AuthFailure) AppSnackbar.error(ctx, state.message);
  },
  child: const _StaticContent(),                    // never rebuilds from state
)
```

## Lists — `ListView.builder`, not `ListView(children: [...])`

For any list > ~10 items or whose count is dynamic, use `.builder` / `.separated`. Builder constructors only build visible items + a small overscan; static-children `ListView(children: [...])` builds them all eagerly.

```dart
// ❌ Builds all 1000 items
ListView(children: items.map((e) => _Tile(e)).toList())

// ✅ Builds only the visible ~10
ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, i) => _Tile(items[i]),
)

// ✅ With separators
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (_, __) => SIZED_BOX_H8,
  itemBuilder: (_, i) => _Tile(items[i]),
)
```

For grids: `GridView.builder` (same rule).

### Slivers when composing inside a scroll view

If a page mixes a header + a list, don't nest `ListView` inside `SingleChildScrollView` (double-scroll → janky). Use `CustomScrollView` with `SliverToBoxAdapter` for fixed sections + `SliverList` / `SliverGrid.builder` for the dynamic list.

### Load-more trigger

```dart
NotificationListener<ScrollEndNotification>(
  onNotification: (n) {
    final m = n.metrics;
    if (m.pixels >= m.maxScrollExtent - 200 &&
        state.hasMore &&
        state.status != FoodListStatus.LOADING_MORE) {
      context.read<FoodListBloc>().add(const FoodListLoadMore());
    }
    return false;
  },
  child: ListView.builder(...),
)
```

The `-200` threshold pre-fetches before the user hits the bottom. Tune 200-400 on slow networks (more pre-fetch), 100-200 on fast (snappier).

## Image sizing — `cacheWidth` is mandatory

Flutter's image cache holds DECODED pixel buffers in memory. A 4000×3000 JPEG fully decoded is ~48 MB; multiplied across a feed of 20 thumbnails, that's a GC stall.

```dart
// ❌ Decodes full resolution
Image.network(url, width: 80, height: 80)

// ✅ Decodes at display resolution (2× for retina)
Image.network(url, width: 80, height: 80, cacheWidth: 160, cacheHeight: 160)
```

Rules:

- Always pass `width` + `height` (layout shouldn't depend on async image load).
- Always pass `cacheWidth` (+ optional `cacheHeight`) at 2× logical for retina.
- For large hero images, skip `cacheWidth` — full res is genuinely needed.
- For lists of network images, consider `cached_network_image` (disk cache + retry) — requires user approval to add.

## `RepaintBoundary` for expensive painters

If a widget repaints often (animation, child of a `ListView` with frequent updates) and its subtree is expensive, wrap in `RepaintBoundary` to isolate its layer:

```dart
RepaintBoundary(
  child: CustomPaint(painter: ExpensiveChartPainter(...)),
)
```

Flutter then caches the rasterized output and only repaints when the boundary's content changes — neighbours' repaints don't cascade in.

Don't `RepaintBoundary`-everything — it costs an extra layer per use. Reserve for genuine hotspots identified via the Flutter DevTools timeline.

## JSON decoding — `compute(...)` for heavy payloads

JSON decode is synchronous and CPU-bound. Anything ≥ ~5 KB or a list with ≥ 50 entries can hitch the UI thread.

Move heavy parsing to a background isolate via Flutter's `compute(...)`:

```dart
// In service
import 'package:flutter/foundation.dart' show compute;

Future<List<FoodEntity>> _decodeFoods(List raw) async {
  return compute<List, List<FoodEntity>>(
    _parseFoodsTopLevel,
    raw,
  );
}

// Top-level function — required by compute (can't be a closure).
List<FoodEntity> _parseFoodsTopLevel(List raw) {
  return raw
      .map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
      .toList();
}
```

Trade-off: each `compute` hop costs ~1 ms of isolate startup. For tiny payloads (single model, 3-5 fields), inline parse is faster.

Decision matrix:

| Payload | Style |
|---|---|
| Single small object (< ~20 fields, no nested lists) | Inline `Model.fromJson(...)` |
| Anything moderately big (nested objects, lists) | `compute(...)` |
| List of items > 50 entries | `compute(...)` |
| `void` response | No parser; omit |

EatinPal's current auth payloads are tiny — `compute` isn't used today. Add when a list / feed endpoint lands.

## Animations

`AnimationController` MUST be disposed:

```dart
class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();           // CRITICAL — leaks tick callbacks otherwise
    super.dispose();
  }
}
```

`AppCircularProgress` (in `lib/core/widgets/loading_overlay.dart`) is the in-house reference — it correctly disposes its controller.

### Respect reduce-motion

```dart
final duration = MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 250);
```

System a11y setting — ignoring it fails real-world accessibility.

### Duration recipes

| Effect | Duration | Curve |
|---|---|---|
| Button press / focus | 100 ms | `Curves.easeOut` |
| Toggle / small UI change | 200-250 ms | `Curves.easeOutCubic` |
| Page transition (default) | 300 ms | `Curves.easeOutCubic` |
| Bottom sheet enter | 250 ms | `Curves.easeOutCubic` |
| Hero | 350 ms | `Curves.fastOutSlowIn` |
| Snackbar slide-in (project's TweenAnimationBuilder) | 300 ms | `Curves.easeOutCubic` |

## TextField focus + keyboard

- Always wrap form content with `SingleChildScrollView` (or use `resizeToAvoidBottomInset: true` on `Scaffold` — the default) so the keyboard doesn't push content off-screen.
- For modals / bottom sheets, add `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom))` so the keyboard offsets the sheet content.
- Set `keyboardType: TextInputType.emailAddress` etc. — saves the user from finding "@" on a default keyboard.
- `obscureText: true` for passwords; pair with a visibility toggle (see `LoginPage`).

## Network performance

- HTTP timeouts: connect / receive `Duration(seconds: 15)` (configured in `ApiClient`). Adjust per-call via custom options if needed — surface to user for global change.
- Refresh-token rotation is single-flight via `_refreshing ??= _refresh(...)` in `AuthInterceptor` — concurrent 401s share one refresh.
- No response caching yet. When added (via `dio_cache_interceptor`), apply per-endpoint policy — `noCache` for user-sensitive data, `refreshForceCache` for stable feeds.

## Hot-reload friendliness

- BLoCs reset state when their `BlocProvider` rebuilds. Hot-reload preserves the BLoC instance (Flutter caches state objects); to force-reset, hot-restart instead.
- `LocalStorage` persists across reloads + restarts. Use `await di<LocalStorage>().clear()` from a debug menu if you want fast wipe.
- `freezed` codegen — after editing a model source, `flutter analyze` errors until you rerun build_runner. Keep `fvm dart run build_runner watch --delete-conflicting-outputs` in a side terminal during heavy model work.

## Memory hygiene

- **Dispose**: `TextEditingController`, `FocusNode`, `ScrollController`, `AnimationController`, `StreamSubscription`. The analyzer doesn't catch leaks here.
- **Cancel** in-flight requests on widget unmount via `Dio`'s `CancelToken`:
  ```dart
  final cancelToken = CancelToken();
  // ... pass to di<ApiClient>().request(cancelToken: cancelToken)
  @override
  void dispose() {
    cancelToken.cancel('widget disposed');
    super.dispose();
  }
  ```
- **`Bloc.close()`** is automatic when `BlocProvider` unmounts. If you manually subscribe to a `Stream` inside the BLoC, cancel in `close()` (see `03-state-routing.md` § Stream subscription discipline).
- **Image cache** — `PaintingBinding.instance.imageCache.clear()` (and `liveImageCache.clear()`) wipes everything. Useful when switching users.

## DevTools / profiling

```bash
fvm flutter run --profile         # profile mode — release-like + DevTools
fvm flutter run --release         # ship config (no debug helpers, no profiler)
```

In DevTools:

- **Performance tab** — frame timeline, raster vs UI thread split. Jank shows as red.
- **Memory tab** — leak suspects, image cache pressure.
- **Network tab** — inspect Dio calls + responses.
- **Inspector** — widget tree, layout explorer, `RepaintBoundary` boundaries.

Profile on a real device. Debug mode is 2-5× slower than release; never trust debug-mode FPS.

## Common pitfalls

- **Whole-page `BlocBuilder` with no `buildWhen`** — every state emission rebuilds the whole tree, including the AppBar.
- **`ListView(children: [...])` with > 20 items** — eager build, slow first frame.
- **`Image.network` without `cacheWidth`** — memory bloat across lists.
- **JSON decode of 5 MB on the main thread** — visible jank during parse.
- **Forgetting `dispose()` on `TextEditingController` / `FocusNode` / `AnimationController`** — memory leak.
- **`setState` inside a `BlocBuilder` builder** — anti-pattern; lift the state into the BLoC.
- **Using `MediaQuery.of(context)` deep in a build tree without `MediaQuery.sizeOf` (Flutter 3.10+)** — `MediaQuery.of` rebuilds on every metric change (text scaling, padding, orientation). `sizeOf` is more granular.
- **Wrapping single small widgets in `RepaintBoundary`** — extra layer cost without benefit.
- **Profiling in debug mode** — numbers lie; profile in `--profile`.

## See also

- `03-state-routing.md` — `buildWhen` patterns, BLoC vs Listener
- `04-networking.md` — `ApiClient` timeouts, interceptor chain
- `07-theming-ui.md` — image loading, animations, `AppCircularProgress`
- `08-platform.md` — `LocalStorage`, deep-link service lifecycle
- `CLAUDE.md` § Critical rules — performance is not a "rule" but tight rebuilds + correct disposal are part of "definition of done"

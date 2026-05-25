---
name: deep-links
description: Use when adding deep-link support — Universal Links (iOS), App Links (Android), custom schemes, in-app links. Covers `go_router` parsing, path / query / extra params, auth-gated deep links (router guard interaction), cold-start (handled in `main.dart`) vs warm-start (via `DeepLinkService`).
---

# Skill: Deep links

## When to use

Adding support for opening the app at a specific route from outside — push notification tap, email link, OS share, marketing campaign. Or: shareable URLs that resolve to the same in-app screen.

## Architecture in EatinPal

Two entry points cover both timing modes:

| Mode | Handler | File |
|---|---|---|
| **Cold-start** (app launches FROM the link) | `_determineInitialRoute()` reads `sl<AppLinks>().getInitialLink()` and may pre-stash data in `LocalStorage` | `lib/main.dart` |
| **Warm-start** (app already running, OS forwards the URI) | `DeepLinkService.init()` listens to `AppLinks().uriLinkStream` and calls `context.go(...)` | `lib/core/deeplink/deeplink_service.dart` |

`DeepLinkService` is registered in `service_locator.dart` and started inside `App.initState()` (`sl<DeepLinkService>()..init()`).

## What `go_router` gives you for free

`GoRouter` resolves the incoming URI against the route table for both cold-start and warm-start. The OS-level Universal Links / App Links plumbing is platform config (§ Per-flavor below).

```dart
// User opens https://eatinpal.com/food/123
// → GoRouter matches RoutePaths.FOOD_DETAIL = '/food/:id'
// → builder receives state.pathParameters['id'] = '123'
```

## Route path conventions

Use `:param` for path segments; read in the route's `builder`:

```dart
GoRoute(
  path: '/food/:id',
  name: RouteNames.FOOD_DETAIL,
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '');
    final source = state.uri.queryParameters['source']; // ?source=email
    if (id == null) return const NotFoundPage();
    return FoodDetailPage(id: id, source: source);
  },
),
```

| Field | Read via | Use for |
|---|---|---|
| Path parameter | `state.pathParameters['id']` | Required identifiers (`/food/:id`) |
| Query parameter | `state.uri.queryParameters['key']` | Optional / cross-cutting (`?source=email`) |
| Typed extra | `state.extra as MyArgs?` | In-app-only data (won't survive cold-start from URL) |

Never store data needed for cold-start in `extra` — it's not serialised into the URL.

## Auth-gated deep links

`_guard(BuildContext, GoRouterState)` in `lib/app/router/app_router.dart` is the single redirect point. The deep-link path passes through it. If the user isn't signed in and the route is protected, redirect to `AUTHENTICATION` and remember the intended URI via a query param or a single-use storage key.

Pattern (extend `_guard` only with explicit approval — see `.claude/rules/hands-off.md`):

```dart
Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final signed = await sl<LocalStorage>().signed;
  final destAuth = _DEST_AUTH.contains(state.matchedLocation);

  if (signed && destAuth) return RoutePaths.HOME;
  if (!signed && !destAuth) return RoutePaths.AUTHENTICATION;
  return null;
}
```

For "remember pending deep link → resume after login": save the URI into `LocalStorage` (e.g., `pendingDeepLink`), then on login success read + clear + `context.go(pending ?? RoutePaths.HOME)`.

## Cold-start vs warm-start

| Start | Behaviour | Pitfall |
|---|---|---|
| **Cold-start from URL** | `main.dart` boots: `WidgetsFlutterBinding.ensureInitialized` → `dotenv.load` → `initDependencies` → `_determineInitialRoute` → `runApp(App(initDest: route))` → router resolves URI | Reading the link before DI is initialized → null `sl<AppLinks>()`. The current order (DI first) is correct. |
| **Warm-start** | App already running, OS forwards intent → `AppLinks().uriLinkStream` fires → `DeepLinkService` dispatches `context.go(...)` | Two handlers racing. Only `DeepLinkService` should listen at runtime. |

## Defensive parsing

```dart
GoRoute(
  path: '/food/:id',
  builder: (_, state) {
    final raw = state.pathParameters['id'];
    final id = raw != null ? int.tryParse(raw) : null;
    if (id == null) return const NotFoundPage();
    return FoodDetailPage(id: id);
  },
),

// Catch-all
GoRouter(
  ...,
  errorBuilder: (_, state) => const NotFoundPage(),
)
```

## Per-flavor configuration

### iOS — Universal Links

`ios/Runner/Runner.entitlements` per build config: `com.apple.developer.associated-domains` →

```
applinks:dev.eatinpal.com
applinks:staging.eatinpal.com
applinks:eatinpal.com
```

Host must serve `/.well-known/apple-app-site-association` with matching bundle ID.

### Android — App Links

`android/app/src/main/AndroidManifest.xml` — `<intent-filter android:autoVerify="true">` with `<data android:host="..."/>`. Host must serve `/.well-known/assetlinks.json` with the matching package + sha256 fingerprint.

For dev, custom scheme is often easier: `eatinpal://...`.

## Common pitfalls

- **Storing the deep-link target in `extra`** — in-memory only, dies on cold-start. Use path/query or stash in `LocalStorage`.
- **Skipping pending-deep-link memory after auth redirect** — user lands on home, loses intent.
- **Two listeners** for warm-start — only `DeepLinkService` should subscribe to `uriLinkStream`.
- **One Universal Link host across all flavors** — dev/stg/prod open the same target.
- **No `errorBuilder`** on `GoRouter` → malformed link → confusing crash.

## Testing

```bash
# iOS Simulator
xcrun simctl openurl booted "https://dev.eatinpal.com/food/123"

# Android Emulator
adb shell am start -W -a android.intent.action.VIEW \
    -d "eatinpal://food/123" \
    com.eatinpal.app
```

Always test cold-start (kill the app first) — the warm-start path masks bootstrap-order bugs.

## See also

- `docs/03-state-routing.md` § Deep links — full narrative
- `docs/08-platform.md` — per-flavor host config
- `lib/main.dart` — cold-start handler `_determineInitialRoute`
- `lib/core/deeplink/deeplink_service.dart` — warm-start listener
- `lib/app/router/app_router.dart` — `_guard` for auth gating
- Flutter / go_router deep linking: <https://docs.flutter.dev/ui/navigation/deep-linking>

# Platform config

Environment configuration (`.env` via `flutter_dotenv`), secure / local storage primitives, deep links (`app_links`), permissions, offline UX, and dependencies. The platform layer is everything between "we have a Flutter app" and "we have a Flutter app on iOS and Android serving real users".

## Environment — `flutter_dotenv`

No multi-flavor build is configured today. Environment values come from a single `.env` file at the project root, loaded once at boot.

`pubspec.yaml` declares `.env` as an asset:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

`main.dart` loads it before DI:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(...);
  await dotenv.load();                       // ← load before initDependencies
  await initDependencies();
  final route = await _determineInitialRoute();
  runApp(App(initDest: route));
}
```

Consumers read via the `dotenv.env[...]` map. Real example in `lib/core/network/api_endpoints.dart`:

```dart
abstract final class ApiEndpoints {
  static String get BASE_URL =>
      dotenv.env['BASE_URL'] ?? 'https://eatinpal.nport.link';
  // ...
}
```

Always provide a sensible fallback in the `??` for safety. The `.env` file is gitignored — fresh clones must create their own.

### `.env` template

```
BASE_URL=https://eatinpal.nport.link
# Add more keys as the project grows.
```

### Adding a flavor / multi-env build

Not currently needed. If staging / prod / dev separation becomes a requirement, two viable paths:

1. **Multiple `.env` files** — `.env.dev`, `.env.stg`, `.env.prod`. Pick at build via `--dart-define=ENV=prod` and load the right file in `main.dart`.
2. **Flutter native flavors** — `productFlavors` block in `android/app/build.gradle`, Xcode schemes for iOS, `appFlavor` constant in Dart. Higher setup cost; pays off when you also need different bundle IDs, icons, splash screens per env.

Surface to user before implementing — multi-flavor is a substantial change touching native config + bootstrap.

## Storage primitives

Two storage backends behind a single `LocalStorage` interface (`lib/core/local/local_storage.dart`). Both **hands-off** — extending the interface or adding new keys requires explicit user approval.

### `LocalStorage` interface

```dart
abstract class LocalStorage {
  Future<void> init();

  // Auth tokens — secure (flutter_secure_storage)
  Future<String?> get accessToken;
  Future<String?> get refreshToken;
  Future<void> saveCredentialsToken({required String accessToken, required String refreshToken});
  Future<void> clearCredentialsToken();

  // Verification token (cold-start magic-link carrier) — secure
  Future<String?> get verificationToken;
  Future<void> saveVerificationToken(String token);
  Future<void> clearVerificationToken();

  // Convenience
  Future<bool> get signed;

  // Untyped KV — SharedPreferences
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> setInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> setDouble(String key, double value);
  Future<double?> getDouble(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<List<String>?> getStringList(String key);
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
  Future<void> clear();                       // wipes BOTH prefs and secure
}
```

The interface mixes both backends intentionally — callers don't need to know which keys are secure-encrypted vs prefs-backed. `clear()` wipes both.

### `LocalStorageImpl`

Backed by `flutter_secure_storage` (for tokens) + `shared_preferences` (for everything else). Keys are private constants:

```dart
class LocalStorageImpl implements LocalStorage {
  static const _ACCESS_TOKEN_KEY = 'access_token';
  static const _REFRESH_TOKEN_KEY = 'refresh_token';
  static const _VERIFICATION_TOKEN_KEY = 'verification_token';

  late final FlutterSecureStorage _secure;
  late final SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _secure = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _prefs = await SharedPreferences.getInstance();
  }
  // ...
}
```

Backed by:

- **Android:** EncryptedSharedPreferences (when configured) — currently uses the default `AndroidOptions()` (consider enabling `encryptedSharedPreferences: true` if it becomes a hard requirement; would need a one-time migration).
- **iOS:** Keychain, accessibility `first_unlock` (data unlocked after the first device unlock post-boot — good default for an app that's used after the user has unlocked their phone).

### Registration & init

`init()` is awaited in `service_locator.dart` BEFORE registering as a singleton:

```dart
Future<void> _initCore() async {
  final storage = LocalStorageImpl();
  await storage.init();
  sl.registerSingleton<LocalStorage>(storage);
  // ...
}
```

Always `registerSingleton` (not `registerLazySingleton`) for `LocalStorage` because init is async — registering lazy would re-run init or fail.

### Reading / writing tokens

```dart
// Write (login / refresh success)
await sl<LocalStorage>().saveCredentialsToken(
  accessToken: response.accessToken,
  refreshToken: response.refreshToken,
);

// Read (interceptor, guard)
final token = await sl<LocalStorage>().accessToken;

// Check signed-in
final signed = await sl<LocalStorage>().signed;        // true iff accessToken != null

// Logout
await sl<LocalStorage>().clearCredentialsToken();
```

`AuthInterceptor` reads `accessToken` on every request and `refreshToken` on every 401 — see `04-networking.md` § AuthInterceptor.

### Verification token bridge

Used ONLY for cold-start magic links. `main.dart` saves it before `runApp`; the `VerificationSuccessPage` reads + clears it. See `_determineInitialRoute()` in `01-architecture.md` § Bootstrap order.

### Logout flow

```dart
Future<void> logout(BuildContext context) async {
  await sl<LocalStorage>().clearCredentialsToken();
  // Optionally also clear other user-specific prefs:
  // await sl<LocalStorage>().remove(PrefKeys.LAST_SEEN_FOOD_ID);
  if (context.mounted) context.go(RoutePaths.AUTHENTICATION);
}
```

If you ever add API response caching, also wipe that on logout — user-specific data may have been cached.

## Deep links — `app_links`

`app_links` package handles both warm-start (app already running, URI arrives via OS) and cold-start (app launched from a URI).

### `DeepLinkService`

`lib/core/deeplink/deeplink_service.dart`. Registered as `lazySingleton`:

```dart
sl.registerLazySingleton<DeepLinkService>(
  () => DeepLinkService(navigatorKey, sl<AppLinks>(), sl<LocalStorage>()),
);
```

Lifecycle is managed by `_AppState` in `lib/app/app.dart`:

```dart
class _AppState extends State<App> {
  late final DeepLinkService _deeplink;

  @override
  void initState() {
    super.initState();
    _deeplink = sl<DeepLinkService>()..init();         // start subscription
  }

  @override
  void dispose() {
    _deeplink.dispose();                                // cancel subscription
    super.dispose();
  }
  // ...
}
```

`init()` subscribes to `AppLinks().uriLinkStream`; `dispose()` cancels.

### Cold-start

Cold-start links resolve in `main.dart` BEFORE `runApp` (because `go_router` needs the initial route at construction):

```dart
Future<String> _determineInitialRoute() async {
  final link = await sl<AppLinks>().getInitialLink();
  if (link == null || !link.path.endsWith('/auth/verify')) {
    return RoutePaths.AUTHENTICATION;
  }
  final token = link.queryParameters['token'];
  if (token == null || token.isEmpty) return RoutePaths.AUTHENTICATION;

  final storage = sl<LocalStorage>();
  if (await storage.signed) return RoutePaths.HOME;
  if (isJWTExpired(token)) return RoutePaths.AUTHENTICATION;

  await storage.saveVerificationToken(token);          // bridge: go_router has no initialExtra
  return RoutePaths.VERIFICATION_SUCCESS;
}
```

Pattern for adding a new cold-start handled path:

1. Add a path matcher branch in `_determineInitialRoute()`.
2. Decide what state must survive into the page — stash via `LocalStorage` (one-shot, page clears after read).
3. Route to the right page.

### Warm-start

`DeepLinkService.init()` subscribes to `AppLinks().uriLinkStream`. On each new URI, it inspects the path and calls `navigatorKey.currentContext?.go(...)` (`navigatorKey` is exported from `app_router.dart`).

For a new deep-link path:

1. Add path + name to `RoutePaths` / `RouteNames`.
2. Add the `GoRoute` to `app_router.dart`.
3. Extend `DeepLinkService` with the new path matcher.
4. Extend `_determineInitialRoute()` in `main.dart` if it should also work from cold-start.

### Native intent / Universal Link config

#### Android

`android/app/src/main/AndroidManifest.xml` — declare an intent filter on the main activity:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https"
        android:host="eatinpal.nport.link" />
</intent-filter>
```

Plus a Digital Asset Links file (`https://eatinpal.nport.link/.well-known/assetlinks.json`) for verified App Links.

#### iOS

`ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:eatinpal.nport.link</string>
</array>
```

Plus an Apple App Site Association file (`https://eatinpal.nport.link/.well-known/apple-app-site-association`) declaring the path → app mapping.

Surface to user before editing native config — these are project-wide changes.

## Permissions

EatinPal currently does NOT request runtime permissions. When future features need them (camera for food photo, photo picker for avatar, notifications), add `permission_handler` (requires user approval — `pubspec.yaml` is hands-off).

### Permission flow

```
[trigger]
   ↓
1. Pre-flight: status already granted? → use directly
   ↓ no
2. Rationale UI ("We need access to your camera to scan barcodes")
   ↓ user accepts
3. OS prompt (status: denied → may show again; permanentlyDenied → won't show)
   ↓
4a. Granted → use
4b. Denied → non-blocking inline message; allow re-trigger
4c. Permanently denied → open-settings CTA + explain
```

### Pattern (reference)

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.status;
  if (status.isGranted) return true;

  if (status.isPermanentlyDenied) {
    final openSettings = await _showSettingsPrompt(context);
    if (openSettings) await openAppSettings();
    return false;
  }

  if (status.isDenied) {
    final wantsPrompt = await _showRationale(context);
    if (!wantsPrompt) return false;
  }

  final result = await Permission.camera.request();
  return result.isGranted;
}
```

### Per-OS quirks

#### iOS

- **First ask is the only ask.** Once denied, `.request()` returns the same denial without prompting. Open Settings.
- **Notifications** — iOS requires explicit prompt. Don't request on cold-start; request when user opts in to a feature that needs them.
- **Usage descriptions** required in `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>To take a photo of your meal.</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>To pick a photo for your meal log.</string>
  ```
  Missing this → App Store rejection + runtime crash.

#### Android

- **Android 13+** splits media: `Permission.photos`, `Permission.videos`, `Permission.audio` instead of one storage permission.
- **Android 12+** notifications need explicit `Permission.notification`.
- **Manifest** in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  ```

### Don't auto-trigger on cold-start

Anti-pattern: requesting every permission the app uses on first launch. Reasons:

- Users say no to mass prompts they don't understand.
- Once denied on iOS, you can't ask again.

Trigger each permission just-in-time when the feature is invoked.

## Offline UX

EatinPal does NOT currently have explicit offline handling. The `AuthInterceptor` propagates 401 → silent refresh, and `ErrorHandler` maps `DioExceptionType.connectionError` → `NoInternetException` for the UI to display, but there's no caching or queued-write infrastructure.

### What's already handled

- Network failure mapped to `NoInternetException` with the message `'No internet connection. Please check your network.'` — shown via `AppSnackbar.error`.
- Timeout mapped to `TimeoutException` similarly.

### What's NOT automatic

- **Read caching** — every GET hits the network. To add response caching, integrate `dio_cache_interceptor` (requires user approval — adds three deps including `path_provider` + a cache store).
- **Connectivity awareness** — UI doesn't know if the device is offline until a request fails. Add `connectivity_plus` for active detection.
- **Optimistic writes / queued retries** — POSTs and PATCHs fail outright offline.

### Adding offline support — sketch

If needed in future:

1. Add `connectivity_plus`, expose a `bool isOnline` (or a `Stream<bool>`) via a singleton service registered in `service_locator.dart`.
2. Wrap top-level scaffolds in a `BlocBuilder` / `StreamBuilder` to show a banner when offline.
3. For caching: `dio_cache_interceptor` with `MemCacheStore` in debug, persistent store in release. Wire it into `ApiClient`'s interceptor list (hands-off change → surface to user).
4. For optimistic writes: per-feature pattern — show pending state on the item, roll back on `Left`. Don't try to make this generic; the rollback logic is item-specific.

## Dependencies (`pubspec.yaml`)

`pubspec.yaml` is **hands-off** — adding a dep requires explicit user approval. Current direct deps (verified from source):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  equatable: ^2.0.5
  get_it: ^9.2.1
  dio: ^5.7.0
  go_router: ^17.2.0
  fpdart: ^1.1.0
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  flutter_dotenv: ^6.0.0
  flutter_secure_storage: ^10.0.0
  shared_preferences: ^2.3.2
  app_links: ^7.0.0
```

Dev deps:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.13
  freezed: ^3.2.5
  json_serializable: ^6.8.0
```

Assets:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-VariableFont_opsz,wght.ttf
    - family: Epilogue
      fonts:
        - asset: assets/fonts/Epilogue-VariableFont_wght.ttf
```

### Adding a dep — process

1. Surface the need — explain WHY (what gap it fills, why not a simpler alternative).
2. Wait for user approval.
3. Add to the right section of `pubspec.yaml`.
4. Run `fvm flutter pub get`.
5. Update relevant docs (this file, `04-networking.md` for HTTP-adjacent deps, etc.).

### Forbidden codegen

Any annotation-driven codegen tool BEYOND `freezed` + `json_serializable` is forbidden by default. Examples to avoid:

- `mockito` (`@GenerateMocks`) — use hand-written test doubles or `mocktail` (no codegen).
- `injectable` — DI is hand-wired in `service_locator.dart`.
- `auto_route` — `go_router` is the standard.

Surface to user if a real need arises.

## Failure modes & escape hatches

| Symptom | Likely cause | Fix |
|---|---|---|
| `Type 'ApiClient' is not a subtype` at startup | DI registration order wrong (e.g. resolving `ApiClient` before `Dio` registered) | Check `_initCore()` registers in order: `LocalStorage` → `Dio` → `ApiClient` → `AppLinks` → `DeepLinkService` |
| `BASE_URL` is null / app hits the fallback URL | `.env` not loaded or `BASE_URL` not in it | Confirm `await dotenv.load()` runs before `initDependencies()` in `main.dart`; check `.env` file content |
| 401 on every request | `accessToken` returns null OR refresh-token is also expired/revoked | `AuthInterceptor` clears tokens on refresh failure → guard bounces to `/authentication`. Re-login. |
| Cold-start magic link → wrong page | `_determineInitialRoute()` matcher wrong OR `LocalStorage.saveVerificationToken` not called | Step-debug `_determineInitialRoute()`; verify `link.path` and query params |
| Warm-start magic link does nothing | `DeepLinkService.init()` not called OR subscription cancelled | Check `_AppState.initState()` calls `..init()`; check the stream subscription isn't disposed too early |
| `Pod install failed` (iOS) | Pods stale | `cd ios && pod install` (if that fails, `pod repo update` first) |
| Android Gradle / JDK error | Toolchain mismatch | Confirm Gradle / AGP / Kotlin / Java versions match Flutter 3.41+ requirements |
| `flutter_secure_storage` returns null on Android after upgrade | Key storage migration issue | Wipe app data; consider enabling `encryptedSharedPreferences: true` in `AndroidOptions` |
| `freezed` generated file has wrong shape after upgrading freezed | Need clean regen | `fvm dart run build_runner clean && fvm dart run build_runner build --delete-conflicting-outputs` |

## Common pitfalls

- **Editing `pubspec.yaml` without user approval** — hands-off. Surface first.
- **Reading `dotenv.env['KEY']` without a fallback** — null at runtime if the key is missing. Always provide `?? 'fallback'`.
- **Caching auth tokens in `LocalStorage.setString(...)` instead of `saveCredentialsToken(...)`** — bypasses secure storage. Use the typed token methods.
- **Forgetting `await storage.init()` before `registerSingleton`** — `LateInitializationError` when something reads prefs.
- **Bootstrap order swap** — `initDependencies()` BEFORE `dotenv.load()` makes `ApiClient`'s base URL fall back to the hardcoded default. Order: dotenv → DI → route → runApp.
- **`navigatorKey` exported, but `currentContext` null** — if `DeepLinkService` fires before the first route mounts. Check `_AppState.initState()` runs after `runApp`.
- **Manifest / Info.plist edits without verification** — App Store / Play Store will reject without the right usage descriptions / intent filters.

## See also

- `01-architecture.md` — bootstrap order, hands-off boundary
- `02-conventions.md` — code-generators rule (freezed + json_serializable only)
- `03-state-routing.md` — `_guard` reads `LocalStorage.signed`; `DeepLinkService` calls `navigatorKey.currentContext.go(...)`
- `04-networking.md` — `AuthInterceptor` uses `LocalStorage` tokens; `ApiEndpoints.BASE_URL` reads from dotenv
- `CLAUDE.md` § Critical rules — rule 9 (hands-off — incl. `pubspec.yaml`)
- `lib/main.dart` — bootstrap (dotenv → DI → initial route → runApp)
- `lib/core/local/local_storage.dart` — full storage source
- `lib/core/deeplink/deeplink_service.dart` — deep-link handler
- `lib/core/network/api_endpoints.dart` — `BASE_URL` reads dotenv
- `pubspec.yaml` — current deps

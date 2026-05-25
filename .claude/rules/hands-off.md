---
name: hands-off
description: Foundation files that downstream modules depend on. Don't modify without explicit user authorization — extend or compose instead.
---

# Rule: Hands-off foundation files

## Constraint

Don't modify these files without explicit user authorization. Changes ripple through the whole codebase.

```
# Networking foundation
lib/core/network/api_client.dart
lib/core/network/api_result.dart
lib/core/network/exceptions.dart
lib/core/network/error_handler.dart
lib/core/network/interceptors/auth_interceptor.dart
lib/core/network/interceptors/logging_interceptor.dart

# Local storage abstraction
lib/core/local/local_storage.dart

# UseCase base
lib/core/usecase/usecase.dart

# DI composition root
lib/core/di/service_locator.dart

# Routing
lib/app/router/app_router.dart   (guard + composition root)

# Project-wide config
analysis_options.yaml
pubspec.yaml                       (only when adding deps explicitly requested by the user)
```

If a task seems to require modifying any of these, **stop and ask the user first**. Usually the right move is:

- **Extend** in a subclass or sibling (e.g., a new interceptor in `core/network/interceptors/`, leaving existing ones untouched)
- **Compose** by creating a new sibling file (e.g., new exception subtype in `exceptions.dart` — discuss first; or new typed `ApiResult` variant in `api_result.dart` — discuss first)
- **Add a new helper** elsewhere (e.g., a utility in `lib/core/helpers/`)

## Why

- These files are foundation — every module's data layer depends on them.
- A breaking change here forces re-testing every module.
- They were designed deliberately (Either<AppException, ApiResult<T>> envelope, `LocalStorage` interface, silent refresh-token rotation in `AuthInterceptor` via single-flight `_refreshing`) — changes need design review, not just code review.

## What is NOT hands-off

These files are normal application code — modify freely:

- `lib/core/network/api_endpoints.dart` — add path constants any time
- `lib/app/router/route_names.dart` — add new `RoutePaths` / `RouteNames`
- `lib/core/constants/*` — add tokens to `AppColors`, `AppSpacing`/`AppPadding`/`AppRadius`, `AppTypography`, `AppTheme` (or surface a missing token first — see `.claude/rules/shared-defs.md`)
- `lib/core/helpers/*` — add extensions, validators
- `lib/core/widgets/*` — add cross-module shared widgets
- `lib/core/deeplink/deeplink_service.dart` — extend deep-link routing
- `lib/modules/*` — anywhere within a module folder
- `lib/main.dart`, `lib/app/app.dart` — adjust bootstrap if needed (discuss order changes)

## What to do when you need to modify a hands-off file

1. **Pause** — don't edit silently.
2. **Surface the need** — explain what you want to change and why. Example:

   > "To support a per-request idempotency header, `ApiClient` would need a new param. This requires modifying `lib/core/network/api_client.dart`, which is a hands-off file. Two options:
   > 1. Add the param to `ApiClient.request(...)` directly.
   > 2. Add a new `IdempotencyInterceptor` and register it in `service_locator.dart`.
   >
   > I recommend (2). Approve to proceed?"

3. **Wait for approval.** Don't make the change until the user explicitly says yes.

## Examples

### ✅ Correct — composing a new interceptor

```dart
// lib/core/network/interceptors/metrics_interceptor.dart   ← new file, fine
class MetricsInterceptor extends Interceptor { ... }

// User-approved 1-line edit to service_locator.dart:
final dio = Dio()
  ..interceptors.addAll([
    AuthInterceptor(sl<LocalStorage>()),
    MetricsInterceptor(),             // new
    LoggingInterceptor(),
  ]);
```

### ❌ Incorrect — silently adding to `AuthInterceptor`

```dart
// In lib/core/network/interceptors/auth_interceptor.dart (hands-off!)
class AuthInterceptor extends QueuedInterceptorsWrapper {
  bool _trackMetrics = true;          // ❌ added silently to hands-off file
  // ...
}
```

### ✅ Correct — extending `LocalStorage` via sibling

If you need a new persistence concern (e.g., user preferences cache), discuss whether to:
- Add new methods to the existing `LocalStorage` interface + impl (touches hands-off).
- Create a sibling abstraction (`PreferencesStorage` in `lib/core/local/preferences_storage.dart`) registered separately in `service_locator.dart`.

## See also

- `docs/01-architecture.md` § Hands-off boundary — full list + rationale per file
- `docs/10-ai-harness.md` § Hands-off protocol — how to surface a hands-off touch

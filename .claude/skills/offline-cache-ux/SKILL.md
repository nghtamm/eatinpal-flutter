---
name: offline-cache-ux
description: Use when designing or building UX for offline / spotty network — last-known cache via `shared_preferences` (`LocalStorage`), graceful error states from `NoInternetException`, retry flow, "stale data" hints, no silent failure.
---

# Skill: Offline / cache UX

## When to use

Designing or building a feature that:

- Should keep working (read-only) when the network is gone.
- Needs to surface "we're offline" without breaking the user's flow.
- Caches a list / detail page so it loads instantly on next visit.
- Has destructive actions (POST/PUT/DELETE) that need a clear "you're offline, this won't happen" message.

EatinPal does not currently have a network-aware connectivity service. This skill explains the patterns to add when needed.

## Layers

| Concern | Lives at |
|---|---|
| Persistence | `LocalStorage.setString` / `getString` / `setBool` / etc. (via `sl<LocalStorage>()`) |
| Error type | `NoInternetException` (from `lib/core/network/exceptions.dart`) |
| User feedback | `AppSnackbar.warning(context, 'No internet…')` |
| Refresh trigger | `RefreshIndicator` on list pages |

## Pattern: cache a list on success

```dart
// data/repository/food_repository_impl.dart
@override
Future<Either<AppException, List<FoodEntity>>> fetchFoods() async {
  final result = await _service.fetchFoods();
  return result.fold((left) async {
    // On NoInternet, return cached if present
    if (left is NoInternetException) {
      final cached = await _readCached();
      if (cached != null) return Right(cached);
    }
    return Left(left);
  }, (right) async {
    final items = right.data;
    await _writeCached(items);
    return Right(items);
  });
}

Future<List<FoodModel>?> _readCached() async {
  final raw = await _storage.getString(_CACHE_KEY);
  if (raw == null) return null;
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(FoodModel.fromJson).toList();
}

Future<void> _writeCached(List<FoodModel> items) async {
  final raw = jsonEncode(items.map((e) => e.toJson()).toList());
  await _storage.setString(_CACHE_KEY, raw);
}
```

Then add a state hint (e.g., `isStale: true`) when serving cached data so the UI can surface "showing cached" badge.

## Pattern: BLoC state with `isOffline` flag

Style B (single-class + enum status) accommodates this:

```dart
enum FoodListStatus { INITIAL, LOADING, SUCCESS, FAILURE }

class FoodListState extends Equatable {
  final FoodListStatus status;
  final List<FoodEntity> items;
  final bool isStale;        // cached data, no fresh fetch yet
  final String? error;

  /* ...copyWith, props... */
}
```

In the BLoC:

```dart
final result = await _fetchFoods();
result.fold(
  (left) {
    if (left is NoInternetException && state.items.isNotEmpty) {
      emit(state.copyWith(status: FoodListStatus.SUCCESS, isStale: true));
      return;
    }
    emit(state.copyWith(status: FoodListStatus.FAILURE, error: left.message));
  },
  (right) => emit(state.copyWith(
    status: FoodListStatus.SUCCESS,
    items: right,
    isStale: false,
  )),
);
```

## Pattern: retry + refresh

```dart
RefreshIndicator(
  onRefresh: () async => context.read<FoodListBloc>().add(FoodListRefreshed()),
  child: ListView.builder(...),
)
```

Empty-state with retry button (when no cached data AND offline):

```dart
if (state.status == FoodListStatus.FAILURE && state.items.isEmpty) {
  return _emptyError(
    message: state.error ?? 'Something went wrong.',
    onRetry: () => context.read<FoodListBloc>().add(FoodListFetched()),
  );
}
```

## Pattern: warn before a destructive offline action

```dart
void _submit() async {
  // Optional: pre-check connectivity. EatinPal doesn't ship `connectivity_plus`
  // by default; instead rely on the request failing and handle NoInternetException.
  context.read<FoodAddBloc>().add(FoodAddSubmitted(...));
}

// In the BLoC's listener:
if (state is FoodAddFailure && state.error is NoInternetException) {
  AppSnackbar.warning(
    context,
    'No internet. We didn\'t save your entry — try again when back online.',
  );
}
```

If a connectivity-aware queue (write-while-offline) is needed, surface that as a separate feature — don't sneak it in here.

## Pattern: snackbar feedback consistent

| Situation | Snackbar |
|---|---|
| Read failed, serving cache | `info` "Showing offline data" |
| Read failed, no cache | `error` ErrorHandler message |
| Write failed, offline | `warning` "No internet…" |
| Write failed, server error | `error` ErrorHandler message |
| Refresh while online | none (let the UI just update) |

## Common pitfalls

- **Silently dropping a failed write** — user thinks it saved. Always surface.
- **Caching tokens** in `shared_preferences` — tokens go in `flutter_secure_storage` via `LocalStorage.saveCredentialsToken`. Cache only non-sensitive read data.
- **Cache without versioning** — stale cache from a previous model shape breaks `fromJson`. Either version the key (`_CACHE_KEY = 'food_list_v2'`) or wrap parsing in try/catch and discard on failure.
- **Refreshing on every page open** — wasteful. Prefer "show cached, refresh on pull-to-refresh".
- **Showing "offline" badge persistently** — only when truly serving stale data, not on every error.

## Common storage keys pattern

Storage keys live as `static const _UPPER_SNAKE_CASE` inside `LocalStorageImpl` if app-wide, OR as private constants in the repository/service that owns the cache:

```dart
class FoodRepositoryImpl implements FoodRepository {
  static const _CACHE_KEY = 'food_list_v1';
  // ...
}
```

## See also

- `lib/core/network/exceptions.dart` — `NoInternetException`, `TimeoutException`, `ErrorHandler`
- `lib/core/local/local_storage.dart` — `getString` / `setString` for cache JSON
- `lib/core/widgets/app_snackbar.dart` — feedback API
- `docs/04-networking.md` § Error envelope — full `Either<AppException, T>` flow
- `.claude/skills/ui-states/SKILL.md` — idle/loading/empty/error matrix
- `.claude/skills/perf-mobile/SKILL.md` — list virtualization patterns

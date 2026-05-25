# Adding a new module from scratch

Step-by-step playbook for adding a new feature module to EatinPal.

Use this when scaffolding any new module: nutrition tracking, food search, daily journal, settings, profile, etc. The end-to-end narrative is in `06-modules.md` § Feature build flow; this doc is the copy-paste-friendly playbook.

## Worked example — `food` module

We'll build a minimal `food` module with one endpoint (`GET /foods`) and a paginated list page. Substitute the names with your real module.

### Step 0 — Decide scope

Write a one-paragraph goal before any code:

> "User can browse a paginated list of foods (id, name, calories), refresh by pull-down, load more by scrolling. Tap a row — out of scope for this PR."

Confirm scope with the user if non-trivial.

### Step 1 — Folder skeleton

Create the folder tree under `lib/modules/food/`:

```
lib/modules/food/
├── food.dart                                    # barrel (empty for now)
├── data/
│   ├── models/                                  # populated step 4
│   ├── services/                                # populated step 5
│   └── repository/                              # populated step 6
├── domain/
│   ├── entities/                                # populated step 3
│   ├── repository/                              # populated step 6
│   └── usecases/                                # populated step 7
└── presentation/
    ├── bloc/                                    # populated step 8
    ├── pages/                                   # populated step 9
    └── widgets/                                 # if needed
```

Don't populate the barrel yet — add exports as files land.

### Step 2 — Endpoint + route + name constants

Three small core-side edits FIRST so the rest of the work can reference them:

**`lib/core/network/api_endpoints.dart`** — add a section:

```dart
abstract final class ApiEndpoints {
  // ... existing
  // [FOOD]
  static const String FOODS = '/foods';
  static String foodById(String id) => '/foods/$id';
}
```

**`lib/app/router/route_names.dart`** — add path + name:

```dart
abstract final class RouteNames {
  // ... existing
  static const String FOOD_LIST = 'food-list';
}

abstract final class RoutePaths {
  // ... existing
  static const String FOOD_LIST = '/foods';
}
```

**`lib/app/router/app_router.dart`** — add the `GoRoute` block (you'll uncomment the import + builder after step 9):

```dart
// TODO: import and add GoRoute(path: RoutePaths.FOOD_LIST, name: RouteNames.FOOD_LIST, builder: (_, __) => const FoodListPage())
```

Also update `_DEST_AUTH` if this route should be public for unauthenticated users (probably not for food).

### Step 3 — Entity (`domain/entities/`)

Pure Dart class. No freezed, no codegen.

```dart
// lib/modules/food/domain/entities/food_entity.dart
class FoodEntity {
  final String id;
  final String name;
  final int calories;
  final DateTime loggedAt;

  const FoodEntity({
    required this.id,
    required this.name,
    required this.calories,
    required this.loggedAt,
  });
}
```

Add to barrel:

```dart
// lib/modules/food/food.dart
// [DOMAIN]
export 'domain/entities/food_entity.dart';
```

### Step 4 — Model (`data/models/`)

Freezed + json_serializable. `implements FoodEntity`.

```dart
// lib/modules/food/data/models/food_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:eatinpal/modules/food/domain/entities/food_entity.dart';

part 'food_model.freezed.dart';
part 'food_model.g.dart';

@freezed
abstract class FoodModel with _$FoodModel implements FoodEntity {
  const factory FoodModel({
    required String id,
    required String name,
    required int calories,
    @JsonKey(name: 'logged_at') required DateTime loggedAt,
  }) = _FoodModel;

  factory FoodModel.fromJson(Map<String, dynamic> json) =>
      _$FoodModelFromJson(json);
}
```

Generate:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Commit `food_model.freezed.dart` + `food_model.g.dart`.

Add to barrel:

```dart
// [DATA]
export 'data/models/food_model.dart';
```

### Step 5 — Service (`data/services/`)

Calls `ApiClient`, returns `Either<AppException, ApiResult<T>>`.

```dart
// lib/modules/food/data/services/food_service.dart
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';
import 'package:eatinpal/core/network/api_methods.dart';
import 'package:eatinpal/core/network/api_result.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/food/data/models/food_model.dart';
import 'package:eatinpal/modules/food/domain/entities/food_entity.dart';

class FoodService {
  final ApiClient _client;
  const FoodService(this._client);

  Future<Either<AppException, ApiResult<List<FoodEntity>>>> getFoodList({
    int page = 1,
    int pageSize = 20,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.FOODS,
      method: RestMethod.GET,
      query: {'page': page, 'page_size': pageSize},
      parser: (data) => (data as List)
          .map<FoodEntity>((e) => FoodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

Add to barrel:

```dart
export 'data/services/food_service.dart';
```

### Step 6 — Repository interface + impl

**Interface** (`domain/repository/`):

```dart
// lib/modules/food/domain/repository/food_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/food/domain/entities/food_entity.dart';

abstract class FoodRepository {
  Future<Either<AppException, List<FoodEntity>>> getFoodList({
    int page = 1,
    int pageSize = 20,
  });
}
```

**Impl** (`data/repository/`):

```dart
// lib/modules/food/data/repository/food_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/food/data/services/food_service.dart';
import 'package:eatinpal/modules/food/domain/entities/food_entity.dart';
import 'package:eatinpal/modules/food/domain/repository/food_repository.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodService _service;
  const FoodRepositoryImpl(this._service);

  @override
  Future<Either<AppException, List<FoodEntity>>> getFoodList({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _service.getFoodList(page: page, pageSize: pageSize);
    return result.fold(
      (left) => Left(left),
      (right) => Right(right.data),
    );
  }
}
```

Add to barrel:

```dart
export 'domain/repository/food_repository.dart';
export 'data/repository/food_repository_impl.dart';
```

### Step 7 — UseCase

Multi-field params class because we have `page` + `pageSize`:

```dart
// lib/modules/food/domain/usecases/get_food_list_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/core/usecase/usecase.dart';
import 'package:eatinpal/modules/food/domain/entities/food_entity.dart';
import 'package:eatinpal/modules/food/domain/repository/food_repository.dart';

class GetFoodListParams {
  final int page;
  final int pageSize;
  const GetFoodListParams({this.page = 1, this.pageSize = 20});
}

class GetFoodListUseCase extends UseCase<List<FoodEntity>, GetFoodListParams> {
  final FoodRepository _repository;
  GetFoodListUseCase(this._repository);

  @override
  Future<Either<AppException, List<FoodEntity>>> call(GetFoodListParams params) {
    return _repository.getFoodList(page: params.page, pageSize: params.pageSize);
  }
}
```

For single-field usecases, skip the params class — pass the primitive directly (see `02-conventions.md` § fpdart Either § Single-field usecase params).

Add to barrel:

```dart
export 'domain/usecases/get_food_list_usecase.dart';
```

### Step 8 — BLoC (event + state + bloc)

This list has shared fields across statuses (items, page, hasMore) — use **Style B** (single state class with enum status). See `03-state-routing.md` § Two styles.

**State:**

```dart
// lib/modules/food/presentation/bloc/food_list_state.dart
import 'package:equatable/equatable.dart';
import 'package:eatinpal/modules/food/domain/entities/food_entity.dart';

enum FoodListStatus { INITIAL, LOADING, LOADING_MORE, SUCCESS, FAILURE }

class FoodListState extends Equatable {
  final FoodListStatus status;
  final List<FoodEntity> items;
  final String? error;
  final int page;
  final bool hasMore;

  const FoodListState({
    this.status = FoodListStatus.INITIAL,
    this.items = const [],
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  FoodListState copyWith({
    FoodListStatus? status,
    List<FoodEntity>? items,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return FoodListState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [status, items, error, page, hasMore];
}
```

**Event:**

```dart
// lib/modules/food/presentation/bloc/food_list_event.dart
import 'package:equatable/equatable.dart';

abstract class FoodListEvent extends Equatable {
  const FoodListEvent();

  @override
  List<Object?> get props => [];
}

class FoodListStarted extends FoodListEvent {
  const FoodListStarted();
}

class FoodListRefreshed extends FoodListEvent {
  const FoodListRefreshed();
}

class FoodListLoadMore extends FoodListEvent {
  const FoodListLoadMore();
}
```

**Bloc:**

```dart
// lib/modules/food/presentation/bloc/food_list_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eatinpal/modules/food/domain/usecases/get_food_list_usecase.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_event.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_state.dart';

class FoodListBloc extends Bloc<FoodListEvent, FoodListState> {
  final GetFoodListUseCase _getList;

  FoodListBloc({required GetFoodListUseCase getList})
      : _getList = getList,
        super(const FoodListState()) {
    on<FoodListStarted>(_onStarted);
    on<FoodListRefreshed>(_onRefreshed);
    on<FoodListLoadMore>(_onLoadMore);
  }

  Future<void> _onStarted(FoodListStarted event, Emitter<FoodListState> emit) async {
    if (state.items.isNotEmpty) return;
    emit(state.copyWith(status: FoodListStatus.LOADING));
    final result = await _getList(const GetFoodListParams(page: 1));
    result.fold(
      (left) => emit(state.copyWith(status: FoodListStatus.FAILURE, error: left.message)),
      (right) => emit(state.copyWith(
        status: FoodListStatus.SUCCESS,
        items: right,
        page: 1,
        hasMore: right.length >= 20,
        error: null,
      )),
    );
  }

  Future<void> _onRefreshed(FoodListRefreshed event, Emitter<FoodListState> emit) async {
    final result = await _getList(const GetFoodListParams(page: 1));
    result.fold(
      (left) => emit(state.copyWith(status: FoodListStatus.FAILURE, error: left.message)),
      (right) => emit(state.copyWith(
        status: FoodListStatus.SUCCESS,
        items: right,
        page: 1,
        hasMore: right.length >= 20,
        error: null,
      )),
    );
  }

  Future<void> _onLoadMore(FoodListLoadMore event, Emitter<FoodListState> emit) async {
    if (!state.hasMore || state.status == FoodListStatus.LOADING_MORE) return;
    emit(state.copyWith(status: FoodListStatus.LOADING_MORE));
    final next = state.page + 1;
    final result = await _getList(GetFoodListParams(page: next));
    result.fold(
      (left) => emit(state.copyWith(status: FoodListStatus.FAILURE, error: left.message)),
      (right) => emit(state.copyWith(
        status: FoodListStatus.SUCCESS,
        items: [...state.items, ...right],
        page: next,
        hasMore: right.length >= 20,
        error: null,
      )),
    );
  }
}
```

Add to barrel:

```dart
// [PRESENTATION]
export 'presentation/bloc/food_list_bloc.dart';
export 'presentation/bloc/food_list_event.dart';
export 'presentation/bloc/food_list_state.dart';
```

### Step 9 — Page

```dart
// lib/modules/food/presentation/pages/food_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
import 'package:eatinpal/core/widgets/basic_appbar.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_bloc.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_event.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_state.dart';

class FoodListPage extends StatelessWidget {
  const FoodListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FoodListBloc>()..add(const FoodListStarted()),
      child: const _FoodListView(),
    );
  }
}

class _FoodListView extends StatelessWidget {
  const _FoodListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.SURFACE,
      appBar: const BasicAppBar(title: Text('Foods')),
      body: SafeArea(
        child: BlocConsumer<FoodListBloc, FoodListState>(
          listenWhen: (prev, curr) =>
              prev.status != FoodListStatus.FAILURE &&
              curr.status == FoodListStatus.FAILURE,
          listener: (ctx, state) {
            if (state.error != null) AppSnackbar.error(ctx, state.error!);
          },
          builder: (ctx, state) {
            if (state.status == FoodListStatus.LOADING && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.items.isEmpty) {
              return const Center(child: Text('No foods logged yet'));
            }
            return RefreshIndicator(
              onRefresh: () async => ctx.read<FoodListBloc>().add(const FoodListRefreshed()),
              child: _list(ctx, state),
            );
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context, FoodListState state) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (n) {
        final m = n.metrics;
        if (m.pixels >= m.maxScrollExtent - 200 && state.hasMore) {
          context.read<FoodListBloc>().add(const FoodListLoadMore());
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppPadding.BASE),
        itemCount: state.items.length +
            (state.status == FoodListStatus.LOADING_MORE ? 1 : 0),
        separatorBuilder: (_, __) => SIZED_BOX_H8,
        itemBuilder: (_, i) {
          if (i == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppPadding.BASE),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[i];
          return ListTile(
            title: Text(item.name),
            trailing: Text('${item.calories} kcal'),
          );
        },
      ),
    );
  }
}
```

Add to barrel:

```dart
export 'presentation/pages/food_list_page.dart';
```

### Step 10 — Register DI

Add `_initFood()` to `lib/core/di/service_locator.dart`:

```dart
import 'package:eatinpal/modules/food/food.dart';                  // ← new

Future<void> initDependencies() async {
  await _initCore();
  _initAuth();
  _initFood();                                                     // ← new
}

void _initFood() {
  // [SERVICES]
  sl.registerLazySingleton(() => FoodService(sl<ApiClient>()));

  // [REPOSITORIES]
  sl.registerLazySingleton<FoodRepository>(
    () => FoodRepositoryImpl(sl<FoodService>()),
  );

  // [USECASES]
  sl.registerLazySingleton(() => GetFoodListUseCase(sl<FoodRepository>()));

  // [BLOCS]
  sl.registerFactory(
    () => FoodListBloc(getList: sl<GetFoodListUseCase>()),
  );
}
```

Order matters within the function: services → repositories → usecases → blocs. The mode matters: `lazySingleton` for everything EXCEPT BLoCs (which are `factory` — new instance per page so state resets on re-entry).

### Step 11 — Wire the route

`lib/app/router/app_router.dart`:

```dart
import 'package:eatinpal/modules/food/food.dart';                  // ← new

GoRouter router({String? initDest = RoutePaths.AUTHENTICATION}) {
  return GoRouter(
    // ... existing
    routes: [
      // ... existing
      GoRoute(
        path: RoutePaths.FOOD_LIST,
        name: RouteNames.FOOD_LIST,
        builder: (_, __) => const FoodListPage(),
      ),
    ],
  );
}
```

If this route should be public for unauthenticated users (probably not for food), add `RoutePaths.FOOD_LIST` to `_DEST_AUTH`.

### Step 12 — Verify

```bash
fvm flutter analyze                          # exit 0, no warnings
fvm dart format --set-exit-if-changed .      # exit 0, no diff
fvm flutter test                             # when tests exist
```

Plus a manual smoke test on a real device — cold-start, navigate to `/foods`, verify list loads, pull-to-refresh, scroll to bottom triggers load-more.

### Step 13 — Harness sync

If the module added anything that's enumerated in the docs (e.g. "current modules: auth"), update the doc. For most new modules the impact is light — `docs/00-overview.md` lists `auth` as the sample module; the rest of the docs use `food` only as a hypothetical and don't need updating.

If you added a new dependency, a new shared widget, or a new pattern, update the relevant doc per working principle 7.

## Variations

### No-API module (pure UI)

Skip `data/`, `domain/repository/`, `domain/usecases/`. Just `presentation/`. Still has a BLoC if there's any local state worth modelling; otherwise a `StatefulWidget` suffices.

### Single-field usecase

If the usecase takes only one field, skip the params class. Pass the primitive directly:

```dart
class SearchFoodUseCase extends UseCase<List<FoodEntity>, String> {
  final FoodRepository _repository;
  SearchFoodUseCase(this._repository);

  @override
  Future<Either<AppException, List<FoodEntity>>> call(String query) {
    return _repository.searchFood(query: query);
  }
}

// Call site:
final result = await sl<SearchFoodUseCase>()(query);
```

### No-params usecase

```dart
class GetTodaysCaloriesUseCase extends UseCaseNoParams<int> {
  final FoodRepository _repository;
  GetTodaysCaloriesUseCase(this._repository);

  @override
  Future<Either<AppException, int>> call() {
    return _repository.getTodaysCalories();
  }
}

// Call site:
final result = await sl<GetTodaysCaloriesUseCase>()();
```

### Multi-bloc page

If a page composes two BLoCs (rare — usually a sign that one of them should be a singleton service / repository), use `MultiBlocProvider`:

```dart
return MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => sl<FoodListBloc>()),
    BlocProvider(create: (_) => sl<DailyTotalBloc>()),
  ],
  child: const _FoodListView(),
);
```

### Reusing a BLoC across pages

`registerFactory` gives a new BLoC per `sl<X>()`. If you need to share state across two screens (e.g. a list and a detail picker), share via a singleton repository OR lift the `BlocProvider` to the common ancestor route and pass via `BlocProvider.value`.

## Common pitfalls (specific to scaffolding)

- **Forgot the per-module barrel** — composition root can't import the module. Always emit `<name>/<name>.dart`.
- **Wrong DI registration mode** — registering the BLoC as `lazySingleton` means state persists across pages. Always `registerFactory` for BLoCs.
- **Forgot `..add(const Started())` in `BlocProvider.create`** — the BLoC sits in `Initial` state forever. Fire the first event in `create`.
- **`buildWhen` always `true`** — defeats the optimisation. Compare specific fields.
- **`copyWith` clears a non-null `error` to `null` accidentally** — Dart's `??` semantics mean `copyWith(error: null)` falls through to the existing value. For nullable fields you want to actively clear, use a sentinel or split into a dedicated `clearError()` method. The pattern in this doc passes `error: null` AND defaults to `error: null` in the success path — works for the simple case.
- **Forgot to run `build_runner` after editing a freezed source** — `*.freezed.dart` stale, build fails.
- **Mass-edited models with `_ignored: null`-style fields** — `@JsonKey(name: 'snake_case')` is verbose but explicit; don't try to auto-snake_case (that requires a custom converter).

## See also

- `01-architecture.md` — folder layout, hands-off boundary
- `02-conventions.md` — naming, fpdart Either, single-field usecase pattern
- `03-state-routing.md` — BLoC styles, `BlocProvider` lifecycle, `get_it` patterns
- `04-networking.md` — `ApiClient`, `ApiResult`, envelope
- `05-clean-architecture.md` — Service ↔ Repository ↔ UseCase ↔ BLoC contracts
- `06-modules.md` — feature build flow narrative (this doc is the playbook complement)
- `07-theming-ui.md` — design tokens used in the page (`AppColors`, `AppPadding`, etc.)
- `08-platform.md` — `LocalStorage`, deep links (if the module needs them)
- `09-performance.md` — `buildWhen`, `ListView.builder`, image sizing
- `10-ai-harness.md` — working principles + harness sync (apply after every step)
- `CLAUDE.md` — critical rules
- `lib/modules/auth/` — full reference implementation

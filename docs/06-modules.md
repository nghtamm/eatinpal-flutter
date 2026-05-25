# Modules & feature flow

How a feature is structured (module anatomy) and how to build one end-to-end (UI → BLoC → UseCase → Repository → Service → API → routing → DI). This is the "if I were building feature X, what's the playbook" reference.

## Module anatomy

Every feature lives at `lib/modules/<name>/` with three mandatory sub-folders:

```
lib/modules/<name>/
├── <name>.dart                              # MANDATORY per-module barrel
├── data/
│   ├── models/                              # freezed + json_serializable, implements <Name>Entity
│   │   ├── <name>_model.dart
│   │   ├── <name>_model.freezed.dart        # generated — committed
│   │   └── <name>_model.g.dart              # generated — committed
│   ├── services/                            # ApiClient calls
│   │   └── <name>_service.dart
│   └── repository/                          # repository_impl
│       └── <name>_repository_impl.dart
├── domain/
│   ├── entities/                            # plain Dart classes
│   │   └── <name>_entity.dart
│   ├── repository/                          # abstract interface
│   │   └── <name>_repository.dart
│   └── usecases/                            # one file per usecase
│       ├── get_<name>_usecase.dart
│       └── <verb>_<name>_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── <name>_bloc.dart
    │   ├── <name>_event.dart                # Equatable, multi-class
    │   └── <name>_state.dart                # Equatable, multi-class (Style A) or single-class enum status (Style B)
    ├── pages/
    │   ├── <name>_page.dart
    │   └── ...
    └── widgets/                             # module-private
        ├── _xxx.dart
        └── ...
```

### What goes where

| Folder | What |
|---|---|
| `data/models/` | Freezed + json_serializable model. ALWAYS `implements <Entity>` (not `extends`). Generated files committed. |
| `data/services/` | One class per module, takes `ApiClient`, methods return `Future<Either<AppException, ApiResult<T>>>`. |
| `data/repository/` | One impl per repository interface, takes service(s) + optional `LocalStorage`, methods return `Future<Either<AppException, T>>` (domain types). |
| `domain/entities/` | Plain Dart classes. Optional `Equatable`. NO freezed. |
| `domain/repository/` | Abstract interface — domain-side contract. |
| `domain/usecases/` | One file per usecase. Multi-field params get a `<Name>Params` class; single-field passes primitive directly. |
| `presentation/bloc/` | BLoC + event + state. `Equatable`. Style A multi-class (default) OR Style B single-class with enum status (UPPER_SNAKE_CASE values). |
| `presentation/pages/` | `StatelessWidget` (preferred) with `BlocProvider` at the top, `BlocConsumer` / `BlocListener` / `BlocBuilder` consuming. |
| `presentation/widgets/` | Module-private widgets. Often prefixed with `_` if file-private; non-prefixed if exported via the barrel. |

### Common shapes

| Shape | Folders populated | When |
|---|---|---|
| Full feature | data + domain + presentation | Most modules — has API + state |
| Pure UI / informational | presentation only (+ thin entities if rendering domain data from another module) | Static pages — e.g. about, privacy |
| Read-only (no mutations) | data (service + repo, no models if response is primitive), domain, presentation | Settings, profile read |

### Per-module barrel

Mandatory. Exports the public surface, NOT generated `.freezed.dart` / `.g.dart` files.

Real example from `lib/modules/auth/auth.dart`:

```dart
// [DOMAIN]
export 'domain/entities/user_entity.dart';
export 'domain/repository/auth_repository.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/resend_verification_usecase.dart';
export 'domain/usecases/verify_usecase.dart';
export 'domain/usecases/verified_login_usecase.dart';

// [DATA]
export 'data/models/user_model.dart';
export 'data/models/tokens_model.dart';
export 'data/services/auth_service.dart';
export 'data/repository/auth_repository_impl.dart';

// [PRESENTATION]
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/bloc/auth_event.dart';
export 'presentation/bloc/auth_state.dart';
export 'presentation/widgets/auth_textfield.dart';
export 'presentation/pages/authentication_page.dart';
export 'presentation/pages/register_page.dart';
export 'presentation/pages/login_page.dart';
export 'presentation/pages/verify_email_page.dart';
export 'presentation/pages/verification_success_page.dart';
export 'presentation/pages/homepage.dart';
```

Comment groups (`[DOMAIN]`, `[DATA]`, `[PRESENTATION]`) help readers and reflect the architectural intent — `domain` comes first because it's the contract every other layer depends on.

The composition root and consumers import as one unit:

```dart
import 'package:eatinpal/modules/auth/auth.dart';
```

Internal-to-module imports (e.g. a service reaching its module's models) use direct `package:` paths — don't import the module's own barrel from inside the module.

### Cross-module rule

Modules MUST NOT import each other except through the barrel. Even then, it's a yellow flag — usually the right answer is to lift the shared piece to `core/`. Full rationale: `01-architecture.md` § Layering rules.

## Feature build flow (end-to-end)

The expected sequence when adding a feature. The example builds a hypothetical `food` module with a list endpoint.

### 1. Decide scope

Before any code, write a one-paragraph goal:

> "User can see a paginated list of foods they've logged this week, refresh by pull-down, tap a row for detail. Detail screen is out of scope for this iteration."

If multiple approaches are viable, brainstorm 2-4 options. If the goal is clear, plan the file paths and verify steps.

### 2. Scaffold the module

Create the folder structure with placeholder files:

```
lib/modules/food/
├── food.dart                                # barrel (empty for now; populate as files land)
├── data/
│   ├── models/food_model.dart               # freezed stub
│   ├── services/food_service.dart           # ApiClient stub
│   └── repository/food_repository_impl.dart # implements stub
├── domain/
│   ├── entities/food_entity.dart            # plain Dart
│   ├── repository/food_repository.dart      # abstract
│   └── usecases/get_food_list_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── food_list_bloc.dart
    │   ├── food_list_event.dart             # Equatable
    │   └── food_list_state.dart             # Equatable
    ├── pages/food_list_page.dart
    └── widgets/_food_list_item.dart
```

Plus:

- Add `ApiEndpoints.FOODS = '/foods'` (and any helpers like `foodById(id)`) to `lib/core/network/api_endpoints.dart`.
- Add `RoutePaths.FOOD_LIST = '/foods'` + `RouteNames.FOOD_LIST = 'food-list'` to `lib/app/router/route_names.dart`.
- Add the `GoRoute` block to `lib/app/router/app_router.dart`:
  ```dart
  GoRoute(
    path: RoutePaths.FOOD_LIST,
    name: RouteNames.FOOD_LIST,
    builder: (_, __) => const FoodListPage(),
  ),
  ```
- Add `_initFood()` to `lib/core/di/service_locator.dart`:
  ```dart
  Future<void> initDependencies() async {
    await _initCore();
    _initAuth();
    _initFood();
  }

  void _initFood() {
    sl.registerLazySingleton(() => FoodService(sl<ApiClient>()));
    sl.registerLazySingleton<FoodRepository>(
      () => FoodRepositoryImpl(sl<FoodService>()),
    );
    sl.registerLazySingleton(() => GetFoodListUseCase(sl<FoodRepository>()));
    sl.registerFactory(() => FoodListBloc(getList: sl<GetFoodListUseCase>()));
  }
  ```

Run `fvm flutter analyze` — should pass with placeholders only.

### 3. Define the entity (`domain/entities/`)

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

Pure Dart, no codegen. The rest of the app (BLoC, UI, usecases) speaks in `FoodEntity`.

### 4. Define the model (`data/models/`)

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

Then:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Commit `food_model.freezed.dart` and `food_model.g.dart`.

### 5. Define the service (`data/services/`)

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

### 6. Define the repository interface + impl

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

### 7. Define the usecase

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

### 8. Define the BLoC (Style B — single class with enum status, paginated list)

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

### 9. Build the UI

```dart
// lib/modules/food/presentation/pages/food_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
import 'package:eatinpal/core/widgets/basic_appbar.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_bloc.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_event.dart';
import 'package:eatinpal/modules/food/presentation/bloc/food_list_state.dart';
import 'package:eatinpal/modules/food/presentation/widgets/_food_list_item.dart';

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
      appBar: const BasicAppBar(title: Text('My foods')),
      body: BlocConsumer<FoodListBloc, FoodListState>(
        listenWhen: (prev, next) =>
            prev.status != FoodListStatus.FAILURE &&
            next.status == FoodListStatus.FAILURE,
        listener: (ctx, state) {
          if (state.error != null) AppSnackbar.error(ctx, state.error!);
        },
        builder: (ctx, state) {
          if (state.status == FoodListStatus.LOADING && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return _empty(ctx);
          }
          return RefreshIndicator(
            onRefresh: () async => ctx.read<FoodListBloc>().add(const FoodListRefreshed()),
            child: _list(ctx, state),
          );
        },
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
          return FoodListItem(item: state.items[i]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Text('No foods logged yet', style: AppTypography.BODY_MEDIUM),
      );
}
```

### 10. Tests (when present)

- **Unit** — BLoC with a stubbed `GetFoodListUseCase` (returns canned `Either`).
- **Unit** — Repository impl with a stubbed `FoodService`.
- **Widget** — Page smoke test with a stubbed BLoC.
- **Integration** — only on explicit request.

### 11. Verify

Before claiming done:

- `fvm flutter analyze` exit 0 (no warnings)
- `fvm dart format --set-exit-if-changed .` exit 0
- `fvm flutter test` exit 0 (every case passes)
- After freezed source edits: `fvm dart run build_runner build --delete-conflicting-outputs` clean

### 12. Harness sync

If the feature added or changed anything in `lib/core/`, update the relevant doc:

- New shared widget → `07-theming-ui.md` § Shared widgets
- New constant / typedef → `02-conventions.md` § Shared definitions
- New base usecase pattern → `05-clean-architecture.md`
- New API pattern (e.g. WebSocket support added to `ApiClient`) → `04-networking.md`

## Form handling (specialised case)

Forms have specific UX concerns — validation timing, submit guard, controller disposal, modal loading.

Real example pattern from `lib/modules/auth/presentation/pages/login_page.dart`:

```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();
  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      AppSnackbar.success(context, state.message);
      context.go(RoutePaths.HOME);
    } else if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onStateChanged,
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) =>
            (prev is AuthLoading) != (curr is AuthLoading),
        builder: (_, state) => LoadingOverlay(
          isLoading: state is AuthLoading,
          child: Scaffold(
            backgroundColor: AppColors.SURFACE,
            appBar: const BasicAppBar(),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(child: _fields()),
                    _submitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fields() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.XL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            label: 'EMAIL ADDRESS',
            hint: 'Enter your email address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          SIZED_BOX_H20,
          AuthTextField(
            label: 'PASSWORD',
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: Validators.loginPassword,
            suffix: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.MD),
                child: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.NEUTRAL_40,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() => Padding(
        padding: const EdgeInsets.all(AppPadding.XL),
        child: AppButton(label: 'LOGIN', onPressed: _submit, height: 56),
      );
}
```

Key disciplines:

- `BlocProvider` on the outer `StatelessWidget`; the `StatefulWidget` view holds the form controllers.
- `GlobalKey<FormState>` on the `Form` widget. `_formKey.currentState!.validate()` gate before dispatching the event.
- `TextEditingController` per field — DISPOSED in `dispose()`. Forgetting this leaks memory; the analyzer doesn't catch it.
- **No `FocusNode` chain** in the auth module today — `AuthTextField` doesn't take a `focusNode` or `onSubmitted`. If you need a focus chain for a longer form, wrap `TextFormField` directly OR extend `AuthTextField`. Don't fabricate a non-existent prop.
- **No `isLoading` on `AppButton`** — `LoadingOverlay` wraps the whole `Scaffold` and modal-scrims it while `AuthLoading` is the current state. The button stays normal underneath; absorption + scrim prevent interaction.
- Password visibility toggle uses `setState` + a `GestureDetector` suffix on `AuthTextField`. Local UI state stays local — it's not BLoC business.
- `BlocListener` for side-effects (snackbar, navigation). `BlocBuilder` with narrow `buildWhen` for the loading overlay only.
- Validators come from `core/helpers/validators.dart` — `Validators.email`, `Validators.password` (signup — strong), `Validators.loginPassword` (login — only checks non-empty), `Validators.name`.

`AuthTextField` defaults `autovalidateMode: AutovalidateMode.onUserInteraction` — errors appear once the user touches a field. Override to `AutovalidateMode.disabled` if you want submit-only validation on a particular form. Never `AutovalidateMode.always` on login (flashing red mid-keystroke is hostile).

## Adding a feature without a full module

Sometimes you need a one-off: a new endpoint on an existing module, a tweak to an existing screen.

- **New endpoint on an existing module:** add to `ApiEndpoints`, add a method to the service, add a method to the repository interface + impl, add a usecase, register the usecase, add an event to the existing BLoC.
- **New screen reusing existing BLoC:** add the route + page; the page uses `BlocProvider.value` (if sharing the same instance up the tree) or `BlocProvider(create: (_) => sl<...>())` (fresh instance).
- **Tweak existing UI:** view-only edit. No BLoC changes.

## Common pitfalls

- **Forgot the per-module barrel** — composition root can't find module types. Always emit `<name>/<name>.dart`.
- **Module A imports module B's internals (not the barrel)** — even with the barrel, prefer to lift the shared piece to `core/`.
- **Forgot to register a new usecase / BLoC in `service_locator.dart`** — `sl<...>()` throws "Type not registered".
- **Registered BLoC as `lazySingleton`** — state persists across page entries. Always use `registerFactory` for BLoCs.
- **`data` imports `presentation`** — wrong direction; pull the dependency into `domain` or refactor.
- **Service throws on HTTP error instead of returning `Left`** — `ApiClient.request` catches `DioException`. Don't bypass it.
- **Inline parser on a 5 MB list response** — UI janks. Move to `compute(...)` or paginate.
- **`Map<String, dynamic>` in `fromJson` signatures** — that's actually the right type here. The project doesn't use a `JsonMap` typedef. Don't add one prematurely.
- **Hardcoded user-facing strings** — if i18n is added later, all of them need touching. Today the project doesn't have i18n; surface to user before adding `flutter_localizations`.
- **Forgot to dispose `TextEditingController` / `FocusNode`** — memory leak. The analyzer doesn't catch this.
- **Forgot to regenerate after editing freezed source** — `*.freezed.dart` / `*.g.dart` stale, build fails. Run `build_runner build --delete-conflicting-outputs`.

## See also

- `01-architecture.md` — folder layout + layering
- `02-conventions.md` — naming, fpdart Either, code generators
- `03-state-routing.md` — BLoC patterns, `get_it`, `go_router`, AppSnackbar
- `04-networking.md` — `ApiClient` + service + endpoint flow
- `05-clean-architecture.md` — Service ↔ Repository ↔ UseCase ↔ BLoC contracts
- `07-theming-ui.md` — design tokens + shared widgets used in views
- `08-platform.md` — `LocalStorage`, deep links
- `09-performance.md` — list builder, image sizing, BLoC rebuild scoping
- `11-module-scaffold.md` — adding a new module from scratch — copy-paste playbook
- `CLAUDE.md` § Critical rules — rules 5 (modular structure), 6 (networking), 8 (state + routing)
- `lib/modules/auth/` — full reference implementation

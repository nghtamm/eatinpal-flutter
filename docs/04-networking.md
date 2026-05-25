# Networking

The deep reference for the HTTP layer. Covers `ApiClient` (Dio wrapper), `ApiResult<T>` envelope, `Either<AppException, T>` contract, two interceptors (`AuthInterceptor` with silent refresh, `LoggingInterceptor`), error handling, file uploads, and adding a new endpoint end-to-end.

## The pipeline

Every API call follows this path:

```
BLoC handler
   ↓ calls
UseCase
   ↓ calls
Repository (.fold to unwrap ApiResult → T)
   ↓ calls
Service (.request(...) → Either<AppException, ApiResult<T>>)
   ↓ calls
ApiClient.request<T>(endpoint:, method:, parser:, ...)
   ↓
Dio interceptor chain
   ├── AuthInterceptor (queued — attaches Bearer; silent refresh + retry on 401)
   └── LoggingInterceptor (debug formatting)
   ↓
network
```

- BLoC handlers call usecases — they don't touch `ApiClient` or services directly.
- Repositories convert `Either<AppException, ApiResult<T>>` into `Either<AppException, T>` (or whatever shape the domain needs — often just the `message: String` from the envelope, or the unwrapped `data`).
- Services return `Either<AppException, ApiResult<T>>` — they wrap the envelope but never throw HTTP exceptions; `ApiClient` catches `DioException` and converts via `ErrorHandler`.

## `ApiClient` surface

`lib/core/network/api_client.dart` exposes:

```dart
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio, LocalStorage storage) {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.BASE_URL,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    );
    _dio.interceptors.addAll([
      AuthInterceptor(storage),
      LoggingInterceptor(),
    ]);
  }

  Future<Either<AppException, ApiResult<T>>> request<T>({
    required String endpoint,
    required RestMethod method,
    Map<String, dynamic>? query,
    dynamic data,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? parser,
  });

  Future<Either<AppException, ApiResult<T>>> upload<T>({
    required String endpoint,
    required FormData formData,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onProgress,
    T Function(dynamic)? parser,
  });
}
```

| Param | Use |
|---|---|
| `endpoint` | Relative path from `ApiEndpoints.*` (e.g. `'/auth/login'`) |
| `method` | `RestMethod.GET` / `POST` / `PUT` / `PATCH` / `DELETE` |
| `query` | URL query params |
| `data` | Request body (Map, FormData, etc.) |
| `headers` | Extra headers — `Authorization` is set automatically by `AuthInterceptor` |
| `cancelToken` | Standard Dio `CancelToken` — see § Cancellation |
| `parser` | `T Function(dynamic)` — converts the envelope's `data` field to `T`. Optional; if omitted, `data` is cast to `T` directly. |

### `parser:` argument

The optional `parser:` converts the unwrapped envelope payload (`envelope['data']`) to `T`. Three styles:

```dart
// 1. Single object — parse with fromJson.
client.request<UserModel>(
  endpoint: ApiEndpoints.ME,
  method: RestMethod.GET,
  parser: (data) => UserModel.fromJson(data as Map<String, dynamic>),
);

// 2. List — map fromJson over each entry.
client.request<List<FoodModel>>(
  endpoint: ApiEndpoints.FOODS,
  method: RestMethod.GET,
  parser: (data) => (data as List)
      .map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

// 3. Tuple / record — typedef + destructure.
typedef LoginResponse = ({UserModel user, TokensModel tokens});

client.request<LoginResponse>(
  endpoint: ApiEndpoints.LOGIN,
  method: RestMethod.POST,
  data: {'email': email, 'password': password},
  parser: (data) {
    final map = data as Map<String, dynamic>;
    return (
      user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
      tokens: TokensModel.fromJson(map['tokens'] as Map<String, dynamic>),
    );
  },
);

// 4. Void / no payload — parser returns nothing.
client.request<void>(
  endpoint: ApiEndpoints.REGISTER,
  method: RestMethod.POST,
  data: {...},
  parser: (_) {},
);
```

For large lists / nested structures, the parser still runs on the main isolate. Move heavy decoding to a background isolate via `compute(...)` when the payload exceeds ~5 KB and the page is animation-sensitive.

## `RestMethod` enum

```dart
enum RestMethod { GET, POST, PUT, PATCH, DELETE }
```

Values are `UPPER_SNAKE_CASE` per naming rule. Use as `RestMethod.GET`, `RestMethod.POST`, etc. when calling `ApiClient.request(...)`.

## Envelope auto-extraction — `ApiResult<T>`

The backend wraps every response in this envelope:

```json
{
  "status_code": 200,
  "message": "Login successful",
  "data": { /* the actual payload */ }
}
```

`ApiClient._unwrap` extracts:

- `status_code` → `ApiResult.statusCode` (falls back to `response.statusCode` or `200`)
- `message` → `ApiResult.message` (empty string if absent)
- `data` → run through `parser` (or cast to `T` if no parser)

```dart
// lib/core/network/api_result.dart
class ApiResult<T> {
  final int statusCode;
  final String message;
  final T data;

  const ApiResult({
    required this.statusCode,
    required this.message,
    required this.data,
  });
}
```

Services thus receive `ApiResult<T>` where `T` is the parsed `data`. Repositories typically `.fold(...)` and either:

- Return the unwrapped `data` — `Right(right.data)`.
- Return just the `message` — `Right(right.message)`. Common for write operations whose UX just needs a success string.
- Persist token-related fields and propagate the message — `auth_repository_impl.dart` pattern.

### When the envelope shape differs

If a particular endpoint doesn't conform (e.g. third-party integration), wrap the parser to extract the right key, or write a service method that calls `_dio` directly (then map manually to `Either<AppException, T>`).

Modifying `_unwrap` itself is a hands-off change — surface to user first.

## `Either<AppException, T>` contract

`fpdart`'s `Either<L, R>` is the universal result type. `L` is always `AppException` (subclasses below). `R` is whatever the success payload is.

### Service layer

```dart
Future<Either<AppException, ApiResult<LoginResponse>>> login({
  required String email,
  required String password,
}) {
  return _client.request(
    endpoint: ApiEndpoints.LOGIN,
    method: RestMethod.POST,
    data: {'email': email, 'password': password},
    parser: (data) {
      final map = data as Map<String, dynamic>;
      return (
        user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
        tokens: TokensModel.fromJson(map['tokens'] as Map<String, dynamic>),
      );
    },
  );
}
```

### Repository layer

Converts service result into a domain-friendly shape:

```dart
@override
Future<Either<AppException, String>> login({
  required String email,
  required String password,
}) async {
  final result = await _service.login(email: email, password: password);
  return result.fold(
    (left) async => Left(left),
    (right) async {
      await _storage.saveCredentialsToken(
        accessToken: right.data.tokens.accessToken,
        refreshToken: right.data.tokens.refreshToken,
      );
      return Right(right.message);                  // domain only needs the message
    },
  );
}
```

### UseCase layer

```dart
class LoginUseCase extends UseCase<String, LoginParams> {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  @override
  Future<Either<AppException, String>> call(LoginParams params) {
    return _repository.login(email: params.email, password: params.password);
  }
}
```

### BLoC handler

```dart
final result = await _login(LoginParams(email: event.email, password: event.password));
result.fold(
  (left) {
    if (left is ForbiddenException) {
      emit(AuthRequiresVerification(left.message));
    } else {
      emit(AuthFailure(left.message));
    }
  },
  (right) => emit(AuthAuthenticated(right)),
);
```

Always name fold params `left` / `right`. Always check `is <Subclass>` if the BLoC needs to react differently to different error types.

## `AppException` hierarchy

`lib/core/network/exceptions.dart`. Base class + status-specific subclasses:

```dart
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  const AppException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'AppException($statusCode): $message';
}

class BadRequestException extends AppException { /* 400 */ }
class UnauthorizedException extends AppException { /* 401 */ }
class ForbiddenException extends AppException { /* 403 */ }
class NotFoundException extends AppException { /* 404 */ }
class NotAcceptableException extends AppException { /* 406 */ }
class RequestTimeoutException extends AppException { /* 408 */ }
class ConflictException extends AppException { /* 409 */ }
class PayloadTooLargeException extends AppException { /* 413 */ }
class InternalServerErrorException extends AppException { /* 500 */ }
class BadGatewayException extends AppException { /* 502 */ }
class ServiceUnavailableException extends AppException { /* 503 */ }
class GatewayTimeoutException extends AppException { /* 504 */ }
class NetworkException extends AppException { /* misc network */ }
class TimeoutException extends AppException { /* connect/send/receive timeout */ }
class CancelException extends AppException { /* request cancelled */ }
class NoInternetException extends AppException { /* connection error */ }
```

Default messages are fallbacks — `ErrorHandler` overrides with the server's `message` field when present.

Add a new subclass when a new HTTP code needs domain-specific behaviour (e.g. `LockedException` for HTTP 423). Wire it into `ErrorHandler._handleBadResponse` (which is hands-off — surface the change).

## `ErrorHandler`

`lib/core/network/error_handler.dart`. Maps `DioException` → `AppException`.

```dart
abstract final class ErrorHandler {
  static AppException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(message: _MSG_TIMEOUT);
      case DioExceptionType.cancel:
        return const CancelException(message: _MSG_CANCEL);
      case DioExceptionType.connectionError:
        return const NoInternetException(message: _MSG_NO_INTERNET);
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const NetworkException(message: _MSG_UNEXPECTED);
    }
  }

  static AppException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final message = _extractMessage(response?.data);

    switch (statusCode) {
      case 400: return BadRequestException(message: message ?? _MSG_INVALID_REQUEST, data: response?.data);
      case 401: return UnauthorizedException(message: message ?? _MSG_SESSION_EXPIRED, data: response?.data);
      case 403: return ForbiddenException(message: message ?? _MSG_SESSION_EXPIRED, data: response?.data);
      // ... etc
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}
```

The server's `message` field (when present) becomes the user-visible message. Don't surface raw status codes — `BadRequestException.message` is what the snackbar will show. If you need to customize per-endpoint UX, branch in the BLoC after `.fold`.

## Interceptors

Registered in `ApiClient`'s constructor — order is **AuthInterceptor → LoggingInterceptor**.

```dart
_dio.interceptors.addAll([
  AuthInterceptor(storage),
  LoggingInterceptor(),
]);
```

Dio fires `onRequest` in registration order, `onResponse` / `onError` in REVERSE order.

### `AuthInterceptor`

`lib/core/network/interceptors/auth_interceptor.dart` — extends `QueuedInterceptorsWrapper` (queues parallel 401s so refresh only happens once).

**On request:**

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  final token = await _storage.accessToken;
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  handler.next(options);
}
```

Reads `accessToken` from `LocalStorage` (secure). Sets `Authorization: Bearer <token>` if present.

**On 401 error — silent refresh-and-retry:**

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode != 401) return handler.next(err);

  final refresh = await _storage.refreshToken;
  if (refresh == null || refresh.isEmpty) {
    await _storage.clearCredentialsToken();
    return handler.next(err);
  }

  // Single-flight refresh — multiple concurrent 401s share one refresh call.
  final ok = await (_refreshing ??= _refresh(refresh))
      .whenComplete(() => _refreshing = null);
  if (!ok) return handler.next(err);

  final opts = err.requestOptions;
  opts.headers['Authorization'] = 'Bearer ${await _storage.accessToken}';
  try {
    final retry = await _dio.fetch(opts);
    handler.resolve(retry);
  } on DioException catch (error) {
    handler.next(error);
  }
}

Future<bool> _refresh(String token) async {
  try {
    final response = await _dio.post(
      ApiEndpoints.REFRESH,
      data: {'refresh_token': token},
    );
    final rotatedAT = response.data['access_token'];
    final rotatedRT = response.data['refresh_token'];
    if (rotatedAT == null || rotatedRT == null ||
        rotatedAT.isEmpty || rotatedRT.isEmpty) {
      await _storage.clearCredentialsToken();
      return false;
    }
    await _storage.saveCredentialsToken(
      accessToken: rotatedAT,
      refreshToken: rotatedRT,
    );
    return true;
  } on DioException catch (err) {
    final code = err.response?.statusCode;
    if (code == 401 || code == 403) {
      await _storage.clearCredentialsToken();
    }
    return false;
  }
}
```

Key behaviours:

- `_refreshing` is a `Future<bool>?` field — `??=` ensures only ONE refresh runs at a time. Concurrent 401s all await the same future.
- The internal `_dio` for the refresh call is a SEPARATE `Dio` instance (created in the constructor) — avoids recursion through `AuthInterceptor` itself.
- On success: tokens are persisted, the original request is retried with the new Bearer token.
- On failure (refresh expired): both tokens cleared, original 401 propagates.

This is hands-off. To extend (e.g. add 403 force-logout, queue offline writes), surface to user.

### `LoggingInterceptor`

`lib/core/network/interceptors/logging_interceptor.dart`. Logs request, response, error to console. Tuning the formatting / log gating is acceptable; logic changes require approval.

## File uploads

`ApiClient.upload<T>` wraps multipart POST:

```dart
final formData = FormData.fromMap({
  'name': 'avatar',
  'file': await MultipartFile.fromFile(
    file.path,
    filename: 'avatar.png',
  ),
});

final result = await sl<ApiClient>().upload<UploadResult>(
  endpoint: ApiEndpoints.UPLOAD_AVATAR,
  formData: formData,
  onProgress: (sent, total) {
    final pct = sent / total;
    // emit progress state via bloc
  },
  parser: (data) => UploadResult.fromJson(data as Map<String, dynamic>),
);
```

`onProgress` fires per chunk — useful for a progress indicator. `Content-Type: multipart/form-data` is set automatically.

## Cancellation

Pass a `CancelToken`:

```dart
final cancelToken = CancelToken();

// Inside a BLoC:
add(SearchFoodRequested(query, cancelToken: cancelToken));

// Cancel when the user types a new query:
oldCancelToken.cancel('superseded by newer query');
```

The cancelled request lands as `DioExceptionType.cancel` → `ErrorHandler` maps to `CancelException`. Repositories can detect & swallow it:

```dart
result.fold(
  (left) {
    if (left is CancelException) return;       // user's choice — no error UI
    emit(SearchFailure(left.message));
  },
  (right) => emit(SearchSuccess(right)),
);
```

## Service pattern

Each module's service is registered with `registerLazySingleton`, takes `ApiClient` via constructor:

```dart
// lib/modules/auth/data/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/api_client.dart';
import 'package:eatinpal/core/network/api_endpoints.dart';
import 'package:eatinpal/core/network/api_methods.dart';
import 'package:eatinpal/core/network/api_result.dart';
import 'package:eatinpal/core/network/exceptions.dart';
import 'package:eatinpal/modules/auth/data/models/tokens_model.dart';
import 'package:eatinpal/modules/auth/data/models/user_model.dart';

typedef LoginResponse = ({UserModel user, TokensModel tokens});

class AuthService {
  final ApiClient _client;

  const AuthService(this._client);

  Future<Either<AppException, ApiResult<LoginResponse>>> login({
    required String email,
    required String password,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.LOGIN,
      method: RestMethod.POST,
      data: {'email': email, 'password': password},
      parser: (data) {
        final map = data as Map<String, dynamic>;
        return (
          user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
          tokens: TokensModel.fromJson(map['tokens'] as Map<String, dynamic>),
        );
      },
    );
  }

  Future<Either<AppException, ApiResult<void>>> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _client.request(
      endpoint: ApiEndpoints.REGISTER,
      method: RestMethod.POST,
      data: {'email': email, 'password': password, 'name': name},
      parser: (_) {},
    );
  }
}
```

Conventions:

- Constructor takes `ApiClient` as positional `_client` (private). `const` constructor where possible.
- Method names match the action (`login`, `register`, `resendVerification`, `verify`, `verifiedLogin`).
- Always return `Future<Either<AppException, ApiResult<T>>>`.
- `parser: (_) {}` for void-data endpoints.
- Use Dart 3.0+ records / typedefs (`LoginResponse`) for tuple-shaped payloads.

## Endpoint constants

`lib/core/network/api_endpoints.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiEndpoints {
  static String get BASE_URL =>
      dotenv.env['BASE_URL'] ?? 'https://eatinpal.nport.link';

  // [AUTH]
  static const String LOGIN = '/auth/login';
  static const String REGISTER = '/auth/register';
  static const String REFRESH = '/auth/refresh';
  static const String RESEND_VERIFICATION = '/auth/resend-verification';
  static const String VERIFY = '/auth/verify';
  static const String VERIFIED_LOGIN = '/auth/verified-login';
}
```

Conventions:

- `abstract final class` (Dart 3.0+ — locks down inheritance + instantiation).
- `BASE_URL` is a getter, reading from `dotenv` (loaded in `main.dart`).
- Constants are `static const String` with `UPPER_SNAKE_CASE`.
- Group by resource with comment headers (`// [AUTH]`, `// [FOOD]`, ...).
- Path-param helpers when needed:
  ```dart
  static String foodById(String id) => '/foods/$id';
  ```

Add new endpoints here before referencing them from a service.

## Adding an endpoint — end-to-end

1. **Add path** to `lib/core/network/api_endpoints.dart`:
   ```dart
   // [FOOD]
   static const String FOODS = '/foods';
   static String foodById(String id) => '/foods/$id';
   ```

2. **Add request/response models** in `lib/modules/<module>/data/models/`. Freezed + `implements <Entity>`:
   ```dart
   @freezed
   abstract class FoodModel with _$FoodModel implements FoodEntity {
     const factory FoodModel({
       required String id,
       required String name,
       required int calories,
     }) = _FoodModel;
     factory FoodModel.fromJson(Map<String, dynamic> json) => _$FoodModelFromJson(json);
   }
   ```
   Run `fvm dart run build_runner build --delete-conflicting-outputs`.

3. **Add the corresponding entity** in `lib/modules/<module>/domain/entities/`:
   ```dart
   class FoodEntity {
     final String id;
     final String name;
     final int calories;
     const FoodEntity({required this.id, required this.name, required this.calories});
   }
   ```

4. **Add method to the service**:
   ```dart
   Future<Either<AppException, ApiResult<List<FoodEntity>>>> getFoods() {
     return _client.request(
       endpoint: ApiEndpoints.FOODS,
       method: RestMethod.GET,
       parser: (data) => (data as List)
           .map<FoodEntity>((e) => FoodModel.fromJson(e as Map<String, dynamic>))
           .toList(),
     );
   }
   ```

5. **Add to the repository interface** (`domain/repository/`):
   ```dart
   abstract class FoodRepository {
     Future<Either<AppException, List<FoodEntity>>> getFoods();
   }
   ```

6. **Implement in `data/repository/`**:
   ```dart
   class FoodRepositoryImpl implements FoodRepository {
     final FoodService _service;
     const FoodRepositoryImpl(this._service);

     @override
     Future<Either<AppException, List<FoodEntity>>> getFoods() async {
       final result = await _service.getFoods();
       return result.fold((left) => Left(left), (right) => Right(right.data));
     }
   }
   ```

7. **Add a usecase** (`domain/usecases/`):
   ```dart
   class GetFoodsUseCase extends UseCaseNoParams<List<FoodEntity>> {
     final FoodRepository _repository;
     GetFoodsUseCase(this._repository);

     @override
     Future<Either<AppException, List<FoodEntity>>> call() => _repository.getFoods();
   }
   ```

8. **Register everything** in `service_locator.dart` (`_initFood()`).

9. **Call from a BLoC handler**, branch on `.fold`.

Full module flow: `06-modules.md`.

## Common pitfalls

- **`Map<String, dynamic>` everywhere** — that's the actual Dart type for parsed JSON in this project. No `JsonMap` typedef. Don't introduce one unless used by ≥ 3 modules.
- **Service throws instead of returning `Left`** — `ApiClient` catches `DioException`, but if you throw a non-Dio exception inside the parser, the call site is unprepared. Wrap parser logic in `try` if it can throw.
- **Repository forgets to unwrap `ApiResult`** — BLoC ends up with an `ApiResult<T>` instead of `T`. Always `.fold` in the repository and extract `right.data` (or `right.message`).
- **Hard-coded base URL** — always go through `ApiEndpoints.BASE_URL` (reads from dotenv).
- **`AuthInterceptor.onError` swallowing 401** — if you add custom 401 logic somewhere, ensure it doesn't conflict with the interceptor's refresh-and-retry.
- **Sending PATCH/PUT without `Content-Type`** — Dio defaults to `application/json` for `Map` payloads; for `FormData` it's `multipart/form-data`. Pass an explicit header only when the API requires something non-standard (e.g. `Headers.acceptHeader: Headers.jsonContentType` — see `auth_service.dart`'s `verify` method).
- **Race on token after refresh** — handled by `_refreshing` single-flight in `AuthInterceptor`. If you bypass `ApiClient` and call `_dio` directly, you lose this safety.

## See also

- `02-conventions.md` — `Either`, single-field usecase params, code generators
- `03-state-routing.md` — how BLoCs consume `Either`
- `05-clean-architecture.md` — Service ↔ Repository ↔ UseCase flow in detail
- `06-modules.md` — end-to-end feature build (incl. networking step)
- `08-platform.md` — `.env` / dotenv loading, deep-link service
- `CLAUDE.md` § Critical rules — rules 6 (networking), 7 (fpdart Either), 9 (hands-off)
- `lib/core/network/api_client.dart` — source
- `lib/core/network/error_handler.dart` — `DioException` → `AppException` mapping
- `lib/core/network/interceptors/auth_interceptor.dart` — silent refresh
- `lib/modules/auth/data/services/auth_service.dart` — reference service shape
- `lib/modules/auth/data/repository/auth_repository_impl.dart` — reference repository shape

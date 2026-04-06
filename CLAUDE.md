# EatinPal - Flutter Calorie & Nutrition Tracker

## Project Overview
Mobile app (Android + iOS only) for tracking daily calories and nutrition, similar to MyFitnessPal. Backend is NestJS with JWT auth.

## Tech Stack
- **Framework**: Flutter 3.41+ / Dart 3.11+ (managed via FVM)
- **Version Manager**: FVM — always use `fvm flutter` / `fvm dart` instead of bare `flutter` / `dart`
- **State Management**: flutter_bloc (NO freezed for bloc)
- **DI**: get_it (service locator pattern)
- **Network**: Dio with custom ApiClient wrapper
- **Navigation**: go_router
- **Functional Programming**: fpdart (Either for error handling)
- **Models**: freezed + json_serializable (models extend from entities)
- **Local Storage**: flutter_secure_storage (tokens) + shared_preferences (prefs)
- **Environment**: flutter_dotenv

## Architecture
Clean Architecture per module with 3 layers:
- **data**: repository_impl, model, service (API calls)
- **domain**: repository (abstract), usecase, entity
- **presentation**: bloc (bloc/event/state), pages, widgets (module-scoped)

## Folder Structure
```
lib/
  main.dart              # Entry point, only calls App
  app/                   # App setup, router
    app.dart
    router/
  core/                  # Shared logic, no barrel export needed
    constants/           # Colors, spacing, typography, theme
    di/                  # GetIt service locator
    helpers/             # Extensions, utilities
    local/               # Local storage abstraction
    network/             # ApiClient, interceptors, error handling
    use_case/            # Base UseCase class
    widgets/             # Shared widgets across modules
  modules/               # Feature modules
    <module>/
      <module>.dart      # Barrel export file
      data/
      domain/
      presentation/
```

## Coding Conventions

### Naming
- **Variables/functions**: camelCase, short but clear (1 word preferred, 2-3 max)
- **Files**: snake_case (e.g., login_page.dart)
- **Constants**: SNAKE_UPPERCASE (e.g., SIZED_BOX_H16, PRIMARY)
- **Classes**: PascalCase

### Style
- Trailing commas for multi-line/nested brackets
- Minimize comments - code should be self-documenting
- No overly long functions, avoid deep widget nesting
- Always handle null safety, even in models
- Use `abstract final class` for classes that are only containers of static members
- Reusable widgets across modules go in core/widgets

### Patterns
- Use fpdart `Either<AppException, T>` for API responses
- Services call ApiClient, Repositories wrap Services, UseCases wrap Repositories
- Each module has a barrel export file (core does not)
- BLoC: regular classes with equatable, NOT freezed
- Models: freezed + json_serializable, extending from domain entities

### Don'ts
- Don't use freezed for BLoC events/states
- Don't nest widgets more than 3-4 levels deep - extract to methods/widgets
- Don't use magic numbers - use constants from core/constants
- Don't import individual files from other modules - use barrel exports
- Don't put module-specific widgets in core/widgets

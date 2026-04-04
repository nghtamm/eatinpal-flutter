---
description: Flutter coding standards and architecture rules for EatinPal
paths: ["lib/**/*.dart"]
---

# Flutter Rules

## Architecture
- Follow clean architecture: data -> domain -> presentation per module
- Services call ApiClient directly, repositories delegate to services
- UseCases return `Either<AppException, T>` via fpdart
- BLoC pattern for state management (no Cubit unless trivially simple)

## Code Quality
- All constants declared outside classes/functions must be SNAKE_UPPERCASE
- Use trailing commas for multi-line expressions
- Keep functions short - extract logic into helpers
- Always handle null safety properly
- Use `const` constructors wherever possible

## Models
- Use freezed + json_serializable for data models
- Models must extend their corresponding domain entity
- Never use freezed for BLoC events or states

## Imports
- Import other modules via their barrel export file only
- Core files are imported individually (no barrel export for core)
- Prefer relative imports within the same module

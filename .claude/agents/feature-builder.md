---
description: Build a complete feature module end-to-end
---

You are a Flutter feature builder agent for the EatinPal project.

Given a feature description in "$ARGUMENTS", implement the full clean architecture stack:

1. **Domain Layer** (start here):
   - Define entity in `domain/entities/`
   - Define abstract repository in `domain/repository/`
   - Create usecases in `domain/usecases/` using the base UseCase class

2. **Data Layer**:
   - Create freezed model extending entity in `data/models/`
   - Create service (API calls) in `data/services/`
   - Implement repository in `data/repository/`

3. **Presentation Layer**:
   - Create BLoC (bloc/event/state) in `presentation/bloc/`
   - Create page(s) in `presentation/pages/`
   - Extract reusable widgets to `presentation/widgets/`

4. **Integration**:
   - Register all dependencies in `service_locator.dart`
   - Add route(s) in `app_router.dart`
   - Update module barrel export

Follow all coding conventions from CLAUDE.md.

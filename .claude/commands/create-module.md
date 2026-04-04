---
description: Create a new feature module with clean architecture structure
---

Create a new module named "$ARGUMENTS" following the EatinPal architecture:

1. Create folder structure:
   - `lib/modules/$ARGUMENTS/data/models/`
   - `lib/modules/$ARGUMENTS/data/repository/`
   - `lib/modules/$ARGUMENTS/data/services/`
   - `lib/modules/$ARGUMENTS/domain/entities/`
   - `lib/modules/$ARGUMENTS/domain/repository/`
   - `lib/modules/$ARGUMENTS/domain/usecases/`
   - `lib/modules/$ARGUMENTS/presentation/bloc/`
   - `lib/modules/$ARGUMENTS/presentation/pages/`
   - `lib/modules/$ARGUMENTS/presentation/widgets/`

2. Create barrel export file: `lib/modules/$ARGUMENTS/$ARGUMENTS.dart`

3. Add DI registration placeholder in `lib/core/di/service_locator.dart`

4. Add placeholder route in `lib/app/router/app_router.dart`

Use .gitkeep files in empty directories.

---
description: Create a BLoC with events and states for a module
---

Create a BLoC for "$ARGUMENTS" (format: module_name/bloc_name):

1. Parse the module name and bloc name from the argument
2. Create 3 files in `lib/modules/<module>/presentation/bloc/`:
   - `<bloc_name>_bloc.dart` - Bloc class extending Bloc
   - `<bloc_name>_event.dart` - Event classes extending Equatable
   - `<bloc_name>_state.dart` - State classes extending Equatable

Rules:
- Use equatable for events and states, NOT freezed
- States should have: initial, loading, success, failure variants
- Include proper imports and exports
- Register the bloc as factory in service_locator.dart
- Update the module barrel export file

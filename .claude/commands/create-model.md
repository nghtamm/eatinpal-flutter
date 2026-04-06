---
description: Create a freezed model with its corresponding entity
---

Create a model and entity for "$ARGUMENTS" (format: module_name/model_name):

1. Parse the module name and model name from the argument
2. Create entity in `lib/modules/<module>/domain/entities/<model_name>_entity.dart`:
   - Plain Dart class with final fields
   - Constructor with named parameters
3. Create model in `lib/modules/<module>/data/models/<model_name>_model.dart`:
   - Use @freezed annotation
   - Extend from the entity class
   - Include fromJson factory
   - Handle null safety for all fields

Rules:
- Use freezed_annotation and json_annotation
- Add `part '<model_name>_model.freezed.dart'` and `part '<model_name>_model.g.dart'`
- Run `fvm dart run build_runner build --delete-conflicting-outputs` after creation
- Update the module barrel export file

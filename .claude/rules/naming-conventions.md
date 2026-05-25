---
name: naming-conventions
description: Files snake_case, classes PascalCase, methods/vars camelCase (short), constants and enum values UPPER_SNAKE_CASE, private members prefixed with underscore. Private widget-builder helpers in pages drop the `_build` prefix.
---

# Rule: Naming conventions

## Constraint

| Element | Convention | Example |
|---|---|---|
| File | `snake_case.dart` | `login_page.dart`, `auth_repository_impl.dart` |
| Folder | `snake_case` | `core/network/`, `modules/auth/` |
| Class / Enum / Typedef / Mixin | `PascalCase` | `AuthBloc`, `AppSnackbarType` |
| Method / parameter / local variable | `camelCase` (1 word preferred, 2–3 max) | `email`, `submit()`, `accessToken` |
| Constant (top-level OR `static const`) | `UPPER_SNAKE_CASE` | `SIZED_BOX_H16`, `AppColors.PRIMARY`, `_ACCESS_TOKEN_KEY` |
| Enum value | `UPPER_SNAKE_CASE` | `RestMethod.GET`, `AppSnackbarType.SUCCESS` |
| Private member | prefix `_` | `_emailController`, `_obscurePassword` |
| Boolean | prefix `is`, `has`, `can`, `should` | `isLoading`, `hasMore`, `canRetry` |
| Route path / name | `UPPER_SNAKE_CASE` in `abstract final class` | `RoutePaths.LOGIN`, `RouteNames.HOME` |
| Private widget-builder helper in page | drop `_build` prefix | `_banner()`, NOT `_buildBanner()` |

The last row is project-specific: helper methods that return a `Widget` inside a page/widget file are named `_banner()`, `_content()`, `_title()` etc. The framework's own `build(BuildContext)` is unaffected — it always keeps that name.

## Why

- Consistent casing makes scanning code faster and matches Dart/Flutter ecosystem norms.
- `UPPER_SNAKE_CASE` for constants reads as "fixed, app-wide value" at a glance. The codebase deliberately disables `constant_identifier_names` so this works without per-line ignores.
- Dropping the `_build` prefix on widget builders removes noise — the return type already signals "builds a widget"; the prefix only adds visual clutter when used 10× per page.

## Examples

### ✅ Correct

```dart
// File: lib/modules/auth/presentation/pages/login_page.dart
class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Widget _banner() => Container(/* … */);
  Widget _title() => Text('WELCOME\nBACK');
}

// In lib/core/constants/app_colors.dart
abstract final class AppColors {
  static const PRIMARY = Color(0xFF22C55E);
  static const NEUTRAL_10 = Color(0xFF111827);
}
```

### ❌ Incorrect

```dart
class loginPage extends StatelessWidget { }              // ❌ class camelCase
class _LoginViewState extends State<_LoginView> {
  final formKey = GlobalKey<FormState>();                // ❌ should be _formKey
  bool ObscurePassword = true;                           // ❌ public PascalCase
  Widget _buildBanner() => Container();                  // ❌ drop _build prefix
}

abstract final class AppColors {
  static const primary = Color(0xFF22C55E);              // ❌ should be UPPER_SNAKE_CASE
}
```

## See also

- `docs/02-conventions.md` § Naming — full narrative + decision rationale
- `analysis_options.yaml` — `constant_identifier_names: false`

---
name: form-handling
description: Use when building a form — `Form` + `GlobalKey<FormState>`, `TextFormField` / project `AuthTextField`, validators from `lib/core/helpers/validators.dart`, submit via BLoC, error display, loading overlay, autovalidate modes.
---

# Skill: Form handling

## When to use

Any screen with one or more inputs that the user submits (login, register, edit profile, add food, search, etc.).

Concrete reference: `lib/modules/auth/presentation/pages/login_page.dart`, `register_page.dart` — full form + BLoC + snackbar feedback.

## Pattern

### 1. `GlobalKey<FormState>` + `Form`

```dart
class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthTextField(
            label: 'EMAIL',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          SIZED_BOX_H20,
          AuthTextField(
            label: 'PASSWORD',
            controller: _passwordController,
            obscureText: true,
            validator: Validators.loginPassword,
          ),
          SIZED_BOX_H32,
          AppButton(label: 'LOGIN', onPressed: _submit, height: 56),
        ],
      ),
    );
  }
}
```

### 2. Validators

Add reusable validators to `lib/core/helpers/validators.dart`:

```dart
abstract final class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w.\-]+@[\w.\-]+\.\w+$').hasMatch(value.trim());
    return ok ? null : 'Invalid email';
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }
}
```

A validator returns `null` (valid) or a `String` (error message). Pass to `TextFormField.validator` / `AuthTextField.validator`.

### 3. AuthTextField (project widget)

Module-scoped at `lib/modules/auth/presentation/widgets/auth_textfield.dart`. Wraps `TextFormField` with the project's `InputDecoration` style + `AppColors` border + `AppTypography`. Use for all auth-area inputs. For non-auth forms, build a similar widget at `lib/core/widgets/` or use `TextFormField` directly with `AppTypography` and `AppColors`.

### 4. Submit + loading + feedback via BLoC

```dart
return BlocListener<AuthBloc, AuthState>(
  listener: _onStateChanged,
  child: BlocBuilder<AuthBloc, AuthState>(
    buildWhen: (prev, curr) => (prev is AuthLoading) != (curr is AuthLoading),
    builder: (_, state) => LoadingOverlay(
      isLoading: state is AuthLoading,
      child: /* Form here */,
    ),
  ),
);

void _onStateChanged(BuildContext context, AuthState state) {
  if (state is AuthAuthenticated) {
    AppSnackbar.success(context, state.message);
    context.go(RoutePaths.HOME);
  } else if (state is AuthFailure) {
    AppSnackbar.error(context, state.message);
  }
}
```

Use `LoadingOverlay` (from `lib/core/widgets/`) for full-screen blocking. `BlocBuilder.buildWhen` keeps non-loading rebuilds out.

### 5. Auto-validate modes

| Mode | When |
|---|---|
| `AutovalidateMode.disabled` (default) | Validate only on submit |
| `AutovalidateMode.onUserInteraction` | After user has interacted with the field once; good for forms where errors should reveal as they type after first try |
| `AutovalidateMode.always` | On every keystroke — rarely appropriate (noisy) |

```dart
Form(
  key: _formKey,
  autovalidateMode: AutovalidateMode.onUserInteraction,
  child: ...,
)
```

## Common patterns

### Show/hide password

```dart
bool _obscure = true;

AuthTextField(
  label: 'PASSWORD',
  controller: _passwordController,
  obscureText: _obscure,
  validator: Validators.loginPassword,
  suffix: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _obscure = !_obscure),
    child: Padding(
      padding: const EdgeInsets.all(AppPadding.MD),
      child: Icon(
        _obscure ? Icons.visibility_off : Icons.visibility,
        color: AppColors.NEUTRAL_40,
        size: 22,
      ),
    ),
  ),
)
```

### Multi-step form

Use the same `GlobalKey<FormState>` across steps, OR a state field in the BLoC for `currentStep`. Validate each step before advancing.

### Cross-field validation

`Form.validate()` calls every field's validator independently. For cross-field rules (confirm-password equals password), check in `_submit()` AFTER `validate()`:

```dart
if (!_formKey.currentState!.validate()) return;
if (_passwordController.text != _confirmController.text) {
  AppSnackbar.warning(context, 'Passwords do not match');
  return;
}
```

## Common pitfalls

- **Forgetting `dispose()`** on controllers → memory leak.
- **Validate on every rebuild** — only validate in `_submit()` unless using `autovalidateMode`.
- **Trimming password** — only trim email; never trim password (user might have intentional whitespace).
- **`validate()` returning false silently** — error text appears in `TextFormField` decoration; if hidden by overlap, you might think nothing happens.
- **Showing snackbar mid-typing** — use `BlocListener` only for terminal states (success/error after submit), not per keystroke.
- **Submitting twice** — disable button while `AuthLoading` (already handled by `LoadingOverlay` blocking interaction).

## See also

- `lib/modules/auth/` — full form + BLoC + snackbar reference
- `lib/core/helpers/validators.dart` — `Validators` collection
- `lib/core/widgets/app_button.dart`, `loading_overlay.dart`, `app_snackbar.dart`
- `.claude/rules/state-management.md` — BLoC + Either flow
- `.claude/skills/ui-states/SKILL.md` — idle/loading/error matrix
- `.claude/skills/a11y-patterns/SKILL.md` — `InputDecoration.labelText` for form a11y

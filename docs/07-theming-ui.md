# Theming & UI

The deep reference for design tokens, shared widgets, UI patterns (state matrix, modals, forms, lists, a11y, responsive). Covers everything from "what colour to use" to "how to make a screen feel right".

## Design tokens

All token classes live under `lib/core/constants/`. Static const fields, `UPPER_SNAKE_CASE`. NEVER inline literal colours, sizes, paddings, or radii — always use a token, or surface a gap before adding one.

| File | Holds |
|---|---|
| `lib/core/constants/app_colors.dart` | `AppColors` — primary / secondary / tertiary scales, neutral 10-95, text, semantic (SUCCESS / WARNING / ERROR / INFO), surface, common |
| `lib/core/constants/app_typography.dart` | `AppTypography` — Display / Headline / Title / Body / Label hierarchy |
| `lib/core/constants/app_spacing.dart` | `SIZED_BOX_H*` / `SIZED_BOX_W*` (gap widgets), `SPACE_ZERO`, `SPACER`, `AppPadding` (double scale), `AppRadius` (double scale) |
| `lib/core/constants/app_fonts.dart` | `AppFonts.DISPLAY` / `AppFonts.BODY` (Inter / Epilogue family names) |
| `lib/core/constants/app_theme.dart` | `AppTheme.light` — `ThemeData` composed from tokens |

### `AppColors`

`abstract final class` — purely static. The actual surface (from source):

```dart
// Primary (brand green)
PRIMARY            = Color(0xFF34C77B)
PRIMARY_DARK       = Color(0xFF1FA866)
PRIMARY_SOFT       = Color(0xFFDCFCE7)
PRIMARY_10..PRIMARY_95   // dark → light tone scale

// Secondary, Tertiary — same 10..95 scale pattern.
SECONDARY (60)       = 0xFF6A9B81
TERTIARY (70)        = 0xFFF87171         // used for errors / destructive

// Neutral 10..95 (dark → light)
NEUTRAL_10  = 0xFF161D19  // near-black; used as TEXT_PRIMARY
NEUTRAL_40  = 0xFF59605B  // TEXT_SECONDARY
NEUTRAL_60  = 0xFF8B938C  // TEXT_TERTIARY
NEUTRAL_80  = 0xFFC1C8C2  // BORDER_STRONG
NEUTRAL_90  = 0xFFDDE4DD

// Text aliases
TEXT_PRIMARY   = NEUTRAL_10
TEXT_SECONDARY = NEUTRAL_40
TEXT_TERTIARY  = NEUTRAL_60

// Semantic
SUCCESS = 0xFF22C55E;   SUCCESS_SOFT = 0xFFDCFCE7
WARNING = 0xFFF59E0B;   WARNING_SOFT = 0xFFFEF3C7
ERROR   = 0xFFEF4444;   ERROR_SOFT   = 0xFFFEE2E2
INFO    = 0xFF3B82F6;   INFO_SOFT    = 0xFFDBEAFE

// Surface
SURFACE       = 0xFFF4F9F4  // page background
SURFACE_CARD  = 0xFFFFFFFF  // card background
FIELD_FILL    = 0xFFF1F6F2  // text field fill
BORDER_SOFT   = 0xFFE2E8E3
BORDER_STRONG = NEUTRAL_80
SHADOW_SOFT   = 0x3334C77B  // 20% PRIMARY for soft elevation

// Common
BLACK       = 0xFF000000
WHITE       = 0xFFFFFFFF
TRANSPARENT = 0x00000000
SCRIM       = 0x66000000   // 40% black for modal overlays
```

Use:

```dart
Container(color: AppColors.SURFACE_CARD, ...)
Text('hello', style: TextStyle(color: AppColors.TEXT_PRIMARY))
```

If a new shade is genuinely needed, surface to user — don't invent low-contrast variants. Every PRIMARY / NEUTRAL / TEXT combination is designed to pass WCAG AA contrast on body text.

### `AppTypography`

`abstract final class` — Material 3 hierarchy. All styles default to `color: AppColors.NEUTRAL_10`. From source:

| Group | Styles | Use |
|---|---|---|
| Display | `DISPLAY_LARGE` (40), `DISPLAY_MEDIUM` (32), `DISPLAY_SMALL` (28) | Hero text, large numerals, splash, login title |
| Headline | `HEADLINE_LARGE` (24), `HEADLINE_MEDIUM` (20), `HEADLINE_SMALL` (18) | Page titles, section heads, modals |
| Title | `TITLE_*` | Card titles, dialog titles |
| Body | `BODY_LARGE` (16), `BODY_MEDIUM` (14), `BODY_SMALL` (12) | Paragraph copy, captions |
| Label | `LABEL_LARGE`, `LABEL_MEDIUM`, `LABEL_SMALL` | Buttons, chips, badges, field labels (e.g. `'EMAIL ADDRESS'`) |

Fonts come from `AppFonts.DISPLAY` (Epilogue, used for `DISPLAY_*` / `HEADLINE_*`) and `AppFonts.BODY` (Inter, used for body / label). Configured in `pubspec.yaml`'s `fonts:` section.

```dart
Text('Welcome', style: AppTypography.DISPLAY_LARGE)
Text(body, style: AppTypography.BODY_MEDIUM)
Text('LOGIN', style: AppTypography.LABEL_LARGE.copyWith(letterSpacing: 0.8))
```

Use `.copyWith(...)` to tweak per-instance (color, weight, letter-spacing) without forking the base style.

### `AppSpacing` — gaps, padding, radius

This file mixes three concerns into one (because they all relate to spatial scale). Three groups of constants:

**1. Gap widgets** — top-level `const SizedBox` instances, used in `Column` / `Row` children:

```dart
SIZED_BOX_H2, H4, H6, H8, H10, H12, H16, H20, H24, H32, H40, H48, H56, H64   // height
SIZED_BOX_W2, W4, W6, W8, W10, W12, W16, W20, W24, W32, W40, W48, W56, W64   // width
SPACE_ZERO  = SizedBox.shrink()
SPACER      = Spacer()
```

Use:

```dart
Column(children: [
  _title(),
  SIZED_BOX_H12,
  _subtitle(),
  SIZED_BOX_H32,
  _form(),
])
```

**2. `AppPadding`** — `abstract final class` with `double` constants. Use anywhere a `double` is expected (e.g. `EdgeInsets.all(AppPadding.BASE)`, `EdgeInsets.symmetric(horizontal: AppPadding.XL)`).

```dart
AppPadding.NONE  = 0
AppPadding.XS    = 4
AppPadding.SM    = 8
AppPadding.MD    = 12
AppPadding.BASE  = 16     // most common
AppPadding.LG    = 20
AppPadding.XL    = 24
AppPadding.XXL   = 32
AppPadding.XXXL  = 40
```

**3. `AppRadius`** — `abstract final class` with `double` constants for `BorderRadius.circular(...)`:

```dart
AppRadius.NONE = 0
AppRadius.XS   = 4
AppRadius.SM   = 8
AppRadius.MD   = 12
AppRadius.BASE = 16
AppRadius.LG   = 20
AppRadius.XL   = 24
AppRadius.FULL = 999    // pill / circle
```

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.MD),
    color: AppColors.SURFACE_CARD,
  ),
)

// Top-rounded-only (e.g. bottom sheet):
Container(
  decoration: const BoxDecoration(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppRadius.LG),
      topRight: Radius.circular(AppRadius.LG),
    ),
  ),
)
```

### `AppTheme.light`

`ThemeData` composed from the tokens above. Applied at the root in `app.dart`:

```dart
MaterialApp.router(
  theme: AppTheme.light,
  routerConfig: router(),
  ...
)
```

Dark theme not currently wired — when added, expose `AppTheme.dark` and switch in `MaterialApp.themeMode`.

### Adding a new token

1. Decide which file (`app_colors.dart`, `app_spacing.dart`, etc.).
2. Add a `static const` field with `UPPER_SNAKE_CASE`.
3. If brand-related (new colour family etc.), surface to the user before adding.
4. If already used in ≥ 2 places, the lift is overdue — promote now.

## Shared widgets

`lib/core/widgets/` — composed from tokens, used by ≥ 2 modules. Current set (from source):

| File | What |
|---|---|
| `app_button.dart` | `AppButton` + `enum AppButtonVariant { PRIMARY, SECONDARY, DANGER }` |
| `app_snackbar.dart` | `abstract final class AppSnackbar` + `enum AppSnackbarType { SUCCESS, INFO, WARNING, ERROR }` |
| `basic_appbar.dart` | `BasicAppBar implements PreferredSizeWidget` |
| `loading_overlay.dart` | `LoadingOverlay` (wrapper) + `AppCircularProgress` (custom spinner) |

### `AppButton`

```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.PRIMARY,
    this.height = 52,
  });
}

enum AppButtonVariant { PRIMARY, SECONDARY, DANGER }
```

Behaviour:

- `variant` controls colour mapping:
  - `PRIMARY` → `AppColors.PRIMARY` background, white foreground, disabled = `PRIMARY_80`.
  - `SECONDARY` → `NEUTRAL_90` background, `NEUTRAL_10` foreground, disabled = `NEUTRAL_80`.
  - `DANGER` → `TERTIARY_50` background, white foreground, disabled = `TERTIARY_80`.
- Disabled when `onPressed == null` — Flutter's built-in `ElevatedButton` behaviour. Pass `null` to indicate loading / inactive (see § Loading patterns below).
- Soft shadow under PRIMARY when active (via `AppColors.SHADOW_SOFT`).
- Full pill — `borderRadius: AppRadius.FULL`.
- Label text style: `AppTypography.LABEL_LARGE.copyWith(fontSize: 16, fontWeight: w700, letterSpacing: 0.8)`.

Usage:

```dart
AppButton(label: 'LOGIN', onPressed: _submit, height: 56)
AppButton(label: 'DELETE', variant: AppButtonVariant.DANGER, onPressed: _confirmDelete)

// Disabled while loading:
AppButton(label: 'LOGIN', onPressed: state is AuthLoading ? null : _submit)
```

There is **no `isLoading` prop**. For modal loading, wrap the page in `LoadingOverlay` (below).

### `AppSnackbar`

`abstract final class` — purely static convenience constructors:

```dart
AppSnackbar.success(context, 'Saved');
AppSnackbar.info(context, 'Heads up — session expires soon');
AppSnackbar.warning(context, 'Couldn\'t reach the server. Showing cached data');
AppSnackbar.error(context, 'Sign-in failed. Please try again');

// Full form
AppSnackbar.show(
  context,
  message: 'Custom',
  type: AppSnackbarType.SUCCESS,
  duration: const Duration(seconds: 5),
);
```

`AppSnackbarType` values are `UPPER_SNAKE_CASE`: `SUCCESS`, `INFO`, `WARNING`, `ERROR`. Each maps to an icon + accent colour (PRIMARY for SUCCESS, INFO blue, WARNING amber, TERTIARY_50 red).

Behaviour:

- Calls `ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(...)` — only one snackbar visible at a time. Don't try to stack them.
- Floating behaviour, margin `EdgeInsets.all(AppPadding.BASE)`, rounded corners `AppRadius.MD`.
- Custom animation: `TweenAnimationBuilder` slides + fades the content on insertion.
- Tap the inline close `Icons.close` button to dismiss early.

Duration default: 3 s. Bump to 5–6 s when the message is longer or carries an action.

### `BasicAppBar`

```dart
class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color backgroundColor;     // default AppColors.SURFACE
  final bool centerTitle;          // default true

  const BasicAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor = AppColors.SURFACE,
    this.centerTitle = true,
  });
}
```

`title` is `Widget?` — pass a `Text`, not a `String`:

```dart
const BasicAppBar(title: Text('Sign in'))
const BasicAppBar()                                 // no title (e.g. on login)
BasicAppBar(actions: [IconButton(icon: ..., onPressed: ...)])
```

Behaviour:

- Background defaults to `AppColors.SURFACE` (matches page background — no visible AppBar bar).
- `elevation: 0`, `scrolledUnderElevation: 0`, `surfaceTintColor: AppColors.TRANSPARENT` — no M3 surface tint.
- Default `leading`: chevron-left `IconButton` calling `context.pop()`. Pass `leading: const SizedBox.shrink()` to suppress when on a root route.

### `LoadingOverlay` + `AppCircularProgress`

`LoadingOverlay` is a WRAPPER widget — wrap your `Scaffold` and toggle `isLoading`:

```dart
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color barrierColor;             // default AppColors.SCRIM

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.barrierColor = AppColors.SCRIM,
  });
}
```

While `isLoading`:

- `PopScope(canPop: false)` blocks the system back button — user can't escape mid-request.
- `AbsorbPointer(absorbing: true)` swallows all taps on the child.
- A `ColoredBox(color: barrierColor)` scrim covers everything.
- A centred `AppCircularProgress` spinner overlays the scrim.

Real usage (login page):

```dart
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (prev, curr) => (prev is AuthLoading) != (curr is AuthLoading),
  builder: (_, state) => LoadingOverlay(
    isLoading: state is AuthLoading,
    child: Scaffold(
      backgroundColor: AppColors.SURFACE,
      appBar: const BasicAppBar(),
      body: SafeArea(child: Form(key: _formKey, child: ...)),
    ),
  ),
)
```

`AppCircularProgress` is a custom-painted spinner — uses an `AnimationController` with a `_ChaseArcPainter` (eased start, eased finish per half-cycle). Customisable:

```dart
const AppCircularProgress(
  size: 48,                                 // default 48
  strokeWidth: 6,                           // default 6
  color: AppColors.WHITE,                   // default WHITE (high contrast on SCRIM)
  duration: Duration(milliseconds: 1600),   // default 1600
)
```

Use it inline (without the modal overlay) when you want a small spinner in a card or footer:

```dart
const AppCircularProgress(size: 20, strokeWidth: 3, color: AppColors.PRIMARY)
```

### Adding a new shared widget

When ≥ 2 modules need the same widget:

1. Lift to `lib/core/widgets/<name>.dart`.
2. Compose purely from tokens — no module imports.
3. Make it stateless if possible (or stateful with a clear API).
4. Update this doc's § Shared widgets table.

What does NOT go in `core/widgets/`:

- Module-specific widgets (e.g. `AuthTextField` — only auth uses it) → stay in `modules/auth/presentation/widgets/`.
- Theme tokens themselves → those live in `core/constants/`.
- Validators / helpers → those belong in `core/helpers/`.

## UI patterns

These patterns appear in every data-backed screen. This is the human-facing deep dive.

### State matrix

Any data-backed UI has at least four states. Account for ALL:

| State | Trigger | UI |
|---|---|---|
| **loading-initial** | First fetch, no data yet | Spinner (centre) OR skeleton matching the final layout shape |
| **loaded** | Data present | The real UI |
| **loading-more** | Background fetch with existing data | Inline indicator (footer spinner, top progress bar) — do NOT replace loaded UI |
| **empty** | Fetch succeeded but no data | Empty widget + primary CTA |
| **error** | Fetch failed | Depends on context (see § Error severity) |

Never show a generic full-screen spinner that replaces existing content once data has rendered. Subsequent loading / errors are non-blocking.

### Loading visuals — spinner vs modal overlay vs progress

| Visual | Use when |
|---|---|
| **Modal scrim + spinner** (`LoadingOverlay`) | Blocking submit (sign-in, register, verify) — user shouldn't keep interacting until done |
| **Inline `CircularProgressIndicator`** (Flutter) or `AppCircularProgress` | Mid-content load (list initial load, paged refresh) |
| **Inline footer spinner** | Load-more on a paginated list |
| **`LinearProgressIndicator`** | Top-of-screen background work; or determinate progress (upload) |

Threshold: if work could exceed ~500 ms, show SOMETHING. If it consistently exceeds ~5 s, switch to a determinate progress with cancel.

### Error severity

| Severity | When | Surface |
|---|---|---|
| **Transient** (retryable, user can keep working) | Background save failed, optimistic action rolled back | `AppSnackbar.error(context, message)` |
| **Recoverable** (current view degraded but partially usable) | One card failed to load in a feed | Inline banner at the top of the affected section with retry |
| **Blocking — no data yet** | First load failed, nothing to show | Full-page error widget with retry CTA |
| **Blocking — data already shown** | Refresh failed but old data is visible | `AppSnackbar.warning` ("Couldn't refresh — showing previous data") |
| **Validation** | Form field invalid | Inline below the field (via `AutovalidateMode.onUserInteraction`) |
| **Auth — needs verification** | 403 on login → `AuthRequiresVerification` state | Push to `/verify-email` page with email + `autoResend: true` |

Default snackbar duration: 3 s. Bump to 5–6 s if the message is longer.

### Media loading

#### Network image

```dart
Image.network(
  user.avatarURL!,
  width: 64,
  height: 64,                          // ALWAYS pass dimensions
  fit: BoxFit.cover,
  cacheWidth: 128,                     // 2× logical for retina
  loadingBuilder: (ctx, child, progress) {
    if (progress == null) return child;
    return const _AvatarSkeleton();
  },
  errorBuilder: (ctx, err, stack) => const _AvatarFallback(),
)
```

Always pass `width` / `height` AND `cacheWidth` / `cacheHeight`. Flutter's image cache is in MEMORY; without explicit cache sizes, a 4000×3000 JPEG decoded full-size is ~48 MB. With `cacheWidth: 128` it's ~64 KB.

#### Asset image

```dart
Image.asset('assets/images/onboarding.png', cacheWidth: 1024)
```

Declare assets in `pubspec.yaml` under `flutter.assets`. EatinPal currently declares `.env` and font assets only — add an `assets/images/` entry as needed (requires user approval per `pubspec.yaml` being hands-off).

#### SVG

`flutter_svg` is NOT currently in `pubspec.yaml`. Surface to user if you need SVG support; until then, use PNG.

#### Heavy network images (lists, galleries)

Built-in `Image.network` caches in memory only and evicts under pressure. For grids / feeds, consider adding `cached_network_image` (requires user approval). Alternative: serve small thumbnails + open full image on tap.

### Modal / overlay UX

| Use | When | API |
|---|---|---|
| **Dialog** | Yes/no confirm, short alert | `showDialog(context: ..., builder: ...)` |
| **Bottom sheet — modal** | Sub-flow, multi-step picker, content sheet | `showModalBottomSheet(isScrollControlled: true)` |
| **Bottom sheet — persistent** | Persistent action area at bottom (filter, sort) | `Scaffold.bottomSheet` |
| **Drawer** | Top-level navigation | `Scaffold.drawer` |
| **Snackbar** | Transient feedback | `AppSnackbar.<type>(context, msg)` |
| **Modal loading scrim** | Blocking submit | `LoadingOverlay(isLoading: ..., child: ...)` |

**Sizing rules:**

- Bottom sheet with form fields → `isScrollControlled: true` + `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom))` so the keyboard doesn't cover input.
- Dialogs: max width ~560 dp on tablets via `Dialog(insetPadding: ...)`.
- Don't open a dialog over a dialog — confusing focus + back-button behaviour.

**Dismissal:**

- `Navigator.of(ctx).pop(result)` or `context.pop(result)` from inside builder.
- For destructive confirms, set `barrierDismissible: false` to require an explicit tap.

**Animations:** use Flutter defaults — they're already platform-appropriate.

## Accessibility patterns

Every UI build or review should pass these checks.

### Quick audit checklist

- **Tap target ≥ 48 dp** in any direction. Wrap small icons in `IconButton` or `InkWell` with explicit padding.
- **Icon-only buttons have `tooltip:` or `Semantics(label: ...)`** — otherwise screen readers say "button" with no context.
- **Image buttons have `Semantics(button: true, label: ...)`** — `GestureDetector` on `Image` is invisible to screen readers without it.
- **Form fields have a visible label + accessible label** — `AuthTextField` already takes a `label` parameter that renders above the field; pass it on every input.
- **Text uses tokens** — never inline colour literals. Tokens guarantee theme-defined contrast.
- **Large-text scales gracefully** — test with system font size at 200%. No clipped text, no overflow.
- **State changes announce** — when a dialog opens, a submit fails: use `Semantics(liveRegion: true)` or `SemanticsService.announce(...)`.
- **RTL** — Vietnamese / English don't need RTL; if future locales include Arabic / Hebrew, use `EdgeInsetsDirectional` / `AlignmentDirectional`.

### Patterns

```dart
// ❌ Screen-reader hears "Button". No context.
IconButton(icon: const Icon(Icons.edit), onPressed: _onEdit)

// ✅ Tooltip doubles as accessibility label.
IconButton(
  icon: const Icon(Icons.edit),
  tooltip: 'Edit profile',
  onPressed: _onEdit,
)
```

### Tap target enlargement

The login page's password-visibility toggle uses this pattern (real code):

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
  child: Padding(
    padding: const EdgeInsets.all(AppPadding.MD),      // 12 dp pad → 22 + 12+12 = 46 dp
    child: Icon(
      _obscurePassword ? Icons.visibility_off : Icons.visibility,
      color: AppColors.NEUTRAL_40,
      size: 22,
    ),
  ),
)
```

For a strict 48 dp target, bump to `AppPadding.BASE` (16) on a 24 dp icon → 56 dp, or wrap with `Material + InkWell + SizedBox.square(dimension: 48)`.

## Responsive UI

EatinPal is **Android + iOS only**. No tablet adaptation work is required by default; mobile portrait is the primary target. If a screen ever needs to support tablet / foldable, follow the standard Material 3 window-size class pattern (compact < 600 dp, medium 600-839, expanded ≥ 840) and pick `respond` (scale same layout) vs `adapt` (rearrange) — see Flutter docs.

For now:

- `MediaQuery.sizeOf(context).width` only when truly needed (e.g. capping content max-width on big phones).
- Use `Flexible` / `Expanded` / `SafeArea` liberally; avoid hard-coded pixel widths.
- `SafeArea` is required at the top of any screen with content near the system bars — `BasicAppBar` doesn't wrap content; the page's `body:` should.

## Localisation

EatinPal does NOT currently have i18n wired. All user-facing strings are inline English. When i18n is added (requires `flutter_localizations` + ARB files + `flutter gen-l10n` + user approval), this section will document the pipeline and `context.l10n.<key>` pattern.

Until then: keep strings inline but consistent in tone (verb-noun CTAs, specific error messages, action-oriented empty states).

## Common pitfalls

- **Inline `Color(0xFF...)` / `EdgeInsets.all(13)` / `BorderRadius.circular(7)`** — use tokens. If no token fits, surface a proposal.
- **Inline `fontSize: 14`** — use `AppTypography.<...>.copyWith(...)` (scales with system text size, theme-aware).
- **`ListView(children: [...])` with dynamic data** — use `.builder` / `.separated`.
- **`Image.network` without `cacheWidth`** — memory bloat in lists / feeds.
- **`AppButton(isLoading: ...)`** — that prop doesn't exist. Use `onPressed: null` + a `LoadingOverlay` wrapper for the modal scrim.
- **`BasicAppBar(title: 'Sign in')`** — `title` is `Widget?`, pass `Text('Sign in')`.
- **Stacking snackbars** — `AppSnackbar` hides the previous one first. Don't try to show two at once.
- **`AutovalidateMode.always` on login** — flashing red mid-keystroke is hostile.
- **Hardcoded `EdgeInsets.only(left: ...)`** — fine for LTR-only; breaks if RTL ever lands. Use `EdgeInsetsDirectional` defensively when convenient.

## See also

- `01-architecture.md` — `core/constants/` and `core/widgets/` location, hands-off boundary
- `02-conventions.md` — `UPPER_SNAKE_CASE` for tokens, raw-primitive rule
- `03-state-routing.md` — `AppSnackbar`, `LoadingOverlay`, dialog / sheet APIs
- `06-modules.md` — form handling, end-to-end UI flow
- `09-performance.md` — list builder, image sizing, `RepaintBoundary`, BLoC rebuild scoping
- `CLAUDE.md` § Critical rules — rule 12 (shared defs & raw primitives)
- `lib/core/constants/` — token sources
- `lib/core/widgets/` — shared widget sources
- `lib/modules/auth/presentation/pages/login_page.dart` — reference page using all the patterns above

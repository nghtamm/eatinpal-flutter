---
name: ui-states
description: Use when designing or auditing screens for state coverage — idle / loading / empty / error / success matrix using BLoC + AppSnackbar + LoadingOverlay. Decision tree per state. Microcopy guidelines.
---

# Skill: UI states

## When to use

Every screen with async data or user actions. Skip a state, you ship a bug — "what happens when fetch fails?" or "what does the user see between tap and result?" must always have an answer.

## The five states

| State | Trigger | Typical UI |
|---|---|---|
| **Idle** (default) | Initial mount, no action yet | Static layout, placeholder if appropriate |
| **Loading** | Async action in flight | `LoadingOverlay` (full-screen) OR `AppCircularProgress` (inline) OR skeleton |
| **Empty** | Fetch succeeded, but no data | Friendly illustration + microcopy + (optional) CTA |
| **Error** | Fetch / submit failed | Error message + retry CTA. Tone matters — not "boom!" |
| **Success** | Action completed (often transient) | Snackbar via `AppSnackbar.success` + state transition |

## BLoC → state mapping

### Style A (multi-class, divergent)

Each state is its own class:

```dart
abstract class FoodSearchState extends Equatable { ... }
class FoodSearchInitial extends FoodSearchState {}
class FoodSearchLoading extends FoodSearchState {}
class FoodSearchEmpty extends FoodSearchState {
  final String query;
  const FoodSearchEmpty(this.query);
  @override List<Object?> get props => [query];
}
class FoodSearchSuccess extends FoodSearchState {
  final List<FoodEntity> results;
  const FoodSearchSuccess(this.results);
  @override List<Object?> get props => [results];
}
class FoodSearchFailure extends FoodSearchState {
  final String message;
  const FoodSearchFailure(this.message);
  @override List<Object?> get props => [message];
}
```

### Style B (single-class with enum status)

Better when states share most fields:

```dart
enum FoodSearchStatus { INITIAL, LOADING, SUCCESS, FAILURE }

class FoodSearchState extends Equatable {
  final FoodSearchStatus status;
  final List<FoodEntity> results;
  final String? error;
  final String query;

  bool get isEmpty => status == FoodSearchStatus.SUCCESS && results.isEmpty;

  /* ...copyWith, props... */
}
```

`isEmpty` derives the "empty" state from "success with zero results" — no separate enum value needed.

## Branching in the page

```dart
return BlocConsumer<FoodSearchBloc, FoodSearchState>(
  listener: (context, state) {
    // Side effects: snackbars, navigation
    if (state.status == FoodSearchStatus.FAILURE) {
      AppSnackbar.error(context, state.error ?? 'Search failed');
    }
  },
  builder: (context, state) {
    return LoadingOverlay(
      isLoading: state.status == FoodSearchStatus.LOADING,
      child: Scaffold(
        appBar: const BasicAppBar(),
        body: switch (state.status) {
          FoodSearchStatus.INITIAL => _idle(),
          FoodSearchStatus.LOADING => state.results.isEmpty ? _skeleton() : _list(state),
          FoodSearchStatus.SUCCESS => state.isEmpty ? _emptyState(state.query) : _list(state),
          FoodSearchStatus.FAILURE => _errorState(state),
        },
      ),
    );
  },
);
```

`LoadingOverlay` blocks interaction while the BLoC is `LOADING`. The body switches on status for actual content.

## State recipes

### Loading — full-screen overlay

```dart
LoadingOverlay(
  isLoading: state is XLoading,
  child: /* normal screen */,
)
```

Use when the whole screen is awaiting a single action (login, submit). User can't tap anything underneath.

### Loading — inline skeleton

For lists with progressive loading or initial fetch, prefer skeletons over a blocking overlay:

```dart
Widget _skeleton() => ListView.builder(
  itemCount: 6,
  itemBuilder: (_, _) => Container(
    height: 72,
    margin: const EdgeInsets.all(AppPadding.MD),
    decoration: BoxDecoration(
      color: AppColors.NEUTRAL_95,
      borderRadius: BorderRadius.circular(AppRadius.BASE),
    ),
  ),
);
```

Pair with `Semantics(liveRegion: true, label: 'Loading foods')` for screen readers.

### Empty state

```dart
Widget _emptyState(String query) => Center(
  child: Padding(
    padding: const EdgeInsets.all(AppPadding.XL),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off, size: 64, color: AppColors.NEUTRAL_60),
        SIZED_BOX_H16,
        Text(
          'No results for "$query"',
          style: AppTypography.HEADLINE_SMALL,
          textAlign: TextAlign.center,
        ),
        SIZED_BOX_H8,
        Text(
          'Try a different keyword.',
          style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
);
```

Tone: helpful, not apologetic. Suggest the next action.

### Error state

```dart
Widget _errorState(FoodSearchState state) => Center(
  child: Padding(
    padding: const EdgeInsets.all(AppPadding.XL),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 64, color: AppColors.NEUTRAL_60),
        SIZED_BOX_H16,
        Text(
          state.error ?? 'Something went wrong.',
          style: AppTypography.BODY_MEDIUM,
          textAlign: TextAlign.center,
        ),
        SIZED_BOX_H16,
        AppButton(
          label: 'TRY AGAIN',
          onPressed: () => context.read<FoodSearchBloc>().add(
            FoodSearchRetried(state.query),
          ),
        ),
      ],
    ),
  ),
);
```

Always offer a path forward — retry, go back, contact support. Never a dead end.

### Success — transient snackbar + state transition

Successful submit:

```dart
// In BlocListener
if (state is FoodAddSuccess) {
  AppSnackbar.success(context, 'Food added.');
  context.pop();  // or navigate to next step
}
```

Don't show a persistent success banner on the same screen — the snackbar + UI update is enough.

## Microcopy rules

| Audience | Tone | Example |
|---|---|---|
| Loading | Implicit; no copy needed | (just spinner / skeleton) |
| Empty (no data ever) | Inviting | "Add your first meal to start tracking." |
| Empty (no results for filter) | Suggestive | "No foods matched 'pizza'. Try another keyword." |
| Error (network) | Recoverable | "No internet. Tap to retry." |
| Error (server) | Reassuring | "Service is temporarily unavailable. Please try again shortly." |
| Success | Brief, past tense | "Saved." / "Email sent." |

Use ErrorHandler's fallback messages (`.claude/rules/state-management.md`) when BE doesn't return a custom message.

## Common pitfalls

- **No empty state** — user sees a blank list and assumes the app is broken.
- **No error state** — fetch failure leaves user staring at a spinner forever.
- **Error states without retry** — dead end.
- **Apologetic copy** — "Sorry, we couldn't..." over-applies emotion. "We couldn't load this. Tap to retry." is plenty.
- **Snackbar on every minor success** — disruptive. Reserve for terminal actions (login, save, send).
- **`LoadingOverlay` + skeleton at the same time** — pick one. Overlay = blocking, skeleton = non-blocking.
- **Showing stale data during loading without indicating it** — pair with a subtle "Updating…" hint or use the skeleton.

## See also

- `lib/core/widgets/loading_overlay.dart` — full-screen loading
- `lib/core/widgets/app_circular_progress.dart` — inline spinner
- `lib/core/widgets/app_snackbar.dart` — `success`/`info`/`warning`/`error`
- `docs/07-theming-ui.md` § State matrix — full narrative
- `.claude/rules/state-management.md` — BLoC styles A / B, Either flow
- `.claude/skills/offline-cache-ux/SKILL.md` — stale-cache feedback patterns
- `.claude/skills/a11y-patterns/SKILL.md` — `liveRegion` announcements for state changes

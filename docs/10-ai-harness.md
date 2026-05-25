# AI harness

The AI tooling layer for EatinPal — `CLAUDE.md` as the always-loaded master, `docs/` as the depth layer, working principles, the hands-off protocol, and the harness sync rule. This is the deep reference for HOW agents and humans work together on this codebase.

## Layer cake

```
                  (highest priority, always-loaded)
                                │
                                ▼
          ┌─────────────────────────────────────────────┐
          │ CLAUDE.md                                   │
          │   ├── Tech stack at a glance                │
          │   ├── Architecture at a glance              │
          │   ├── Critical rules (12)                   │
          │   ├── Working principles (10)               │
          │   ├── Commands                              │
          │   └── docs/ map (load on demand)            │
          └─────────────────────────────────────────────┘
                                │
                                ▼
                      (loaded on demand)
          ┌─────────────────────────────────────────────┐
          │ docs/<NN>-<name>.md                         │
          │   deepest reference; pulled when CLAUDE.md  │
          │   links here for depth                      │
          └─────────────────────────────────────────────┘
```

`CLAUDE.md` is the load-bearing summary. `docs/` is the expansion layer that `CLAUDE.md` links out to. The harness is intentionally TWO layers — `CLAUDE.md` + `docs/`. Tool-specific extensions in `.claude/` (sub-agents, rule mirrors, skills) reason from this same source rather than replacing it.

`.claude/` holds tool-specific configuration:

- `.claude/agents/` — sub-agent definitions (see § 10 — `brainstormer`, `planner`, `feature-builder`, `ui-ux-designer`, `tester`, `reviewer`, `debugger`, `researcher`, `docs-writer`).
- `.claude/rules/` — terse rule files mirroring the 12 critical rules for quick injection.
- `.claude/skills/` — load-on-demand expertise modules (deep-links, offline-cache-ux, perf-mobile, a11y-patterns, etc.).
- `.claude/settings.local.json` — local tool config.

The core harness still lives at the repo root (`CLAUDE.md` + `docs/`) for portability.

## Critical rules

Listed in `CLAUDE.md` § Critical rules. The 12 rules are:

1. **Naming** — `02-conventions.md`
2. **Function length** — `02-conventions.md`
3. **Models — freezed + json_serializable, extending entity** — `02-conventions.md`, `05-clean-architecture.md`
4. **BLoC — never freezed** — `03-state-routing.md`
5. **Modular structure** — `01-architecture.md`, `06-modules.md`
6. **Networking** — `04-networking.md`
7. **fpdart Either** — `02-conventions.md`, `04-networking.md`
8. **State + routing** — `03-state-routing.md`
9. **Hands-off files** — `01-architecture.md`
10. **Trailing commas** — `02-conventions.md`
11. **Imports** — `02-conventions.md`
12. **Shared defs & raw primitives** — `02-conventions.md`, `07-theming-ui.md`

Each rule's narrative + examples + decision flow lives in the linked doc. `CLAUDE.md` is the always-loaded summary; the doc is depth.

## Working principles — in detail

Apply to every prompt. The summary is in `CLAUDE.md`; the depth is here.

### 1. Rollback point before big work

Before a broad refactor, a cross-cutting edit, or any hands-off touch:

```bash
git stash push -m "WIP: pre-<refactor>"
# OR
git commit -m "WIP: pre-<refactor>" --allow-empty
```

If the change goes sideways, `git reset --hard HEAD~1` (or `git stash pop` on a clean tree) and start over. **Do not fix-forward through a broken state** — each subsequent attempt makes diagnosis harder. A rollback + re-think is cheaper than untangling.

### 2. Ask or re-fetch when unsure

Three tiers:

1. **Read the file.** Codebase is the source of truth. If a doc and the code disagree, the code wins (and the doc needs fixing — see principle 7).
2. **Read the harness.** `CLAUDE.md` + `docs/<NN>-*.md` + this file. Don't extrapolate from base / other Flutter projects.
3. **Ask the user.** If the code doesn't answer and the harness doesn't answer, ask. Never fabricate an API, a path, or a constant.

Most common fabrication patterns to avoid:

- Inventing widget props (`AppButton(isLoading: true)` — doesn't exist; check the source).
- Inventing helper methods (`Validators.confirmPassword` — only `email`/`password`/`loginPassword`/`name` exist).
- Inventing constants (`AppSpacing.PAD_16` — there's `AppPadding.BASE` for the double).
- Inventing routes (`RoutePaths.PROFILE` — confirm it's in `route_names.dart`).

### 3. One task at a time

Split a big goal into concrete sub-tasks. Surface the split first — "I'll do A, then B, then C. Confirm or push back?" — so the user can redirect if the plan is wrong before you've started.

Complete + verify one sub-task before the next. Don't queue up five edits, then run `flutter analyze` once.

### 4. Stop-and-note on scope creep

While doing A, you spot B (a related bug, a stale doc, a missing constant). Two choices:

- **Note + park.** "Spotted: `Validators.email` accepts `a@b` (no TLD). Out of scope for this task. Track separately?"
- **Ask before fixing.** "While here, I'd fix the regex. Adds ~5 lines, 1 test case. Proceed?"

NEVER silently fix B. Two reasons: (1) the diff stops being about A only, (2) B may be intentional / known-issue and your "fix" regresses something else.

### 5. Definition of done

Before claiming a task complete:

```bash
fvm flutter analyze                                      # exit 0, no warnings
fvm dart format --set-exit-if-changed .                  # exit 0, no diff
fvm flutter test                                         # when tests exist, exit 0
fvm dart run build_runner build --delete-conflicting-outputs   # if any freezed source edited
```

Plus:

- Every test case passes — no `skip:`, no `// ignore: ...` without justification.
- No flaky exceptions ("works on retry") — re-run until you understand the flake.
- Generated `*.freezed.dart` / `*.g.dart` files committed alongside the source change.

### 6. Structure correctness

- **No reverse DI** (`core/` importing `modules/`). The composition root (`service_locator.dart`, `app_router.dart`) is the only `core/`-adjacent location allowed to import modules.
- **No cross-module imports**, even via barrel. Lift shared pieces to `core/`.
- **No hands-off file edits** without explicit user approval (rule 9 + § Hands-off protocol below).
- **Folder layout matches `01-architecture.md`** — `data/` / `domain/` / `presentation/` inside every module, with their canonical sub-folders.
- **Naming matches `02-conventions.md`** — snake_case files, PascalCase classes, UPPER_SNAKE_CASE constants, `_build` prefix dropped on widget helpers.

If you genuinely need to bend a rule, discuss first. Don't surprise the reviewer.

### 7. Harness sync — STRICT, every change, deletions included

Any code change that makes a claim in `CLAUDE.md` or any `docs/<NN>-*.md` inaccurate MUST update the matching lines in the same change. This includes:

- **File paths** — renaming `lib/core/local/local_storage.dart` → `lib/core/storage/local_storage.dart` updates every harness reference.
- **API signatures** — adding a param to `LocalStorage.saveCredentialsToken(...)` updates the snippet in `docs/08-platform.md`.
- **Behaviour** — flipping `AuthInterceptor` to use a different refresh endpoint updates `docs/04-networking.md`.
- **Items mentioned by name** — adding `AppColors.ACCENT_PURPLE` should be reflected in `docs/07-theming-ui.md` § AppColors (if it's a meaningful enough addition to warrant mention).

**Deletions count.** Removing a method / class / route leaves stale references in the docs. Either delete the reference or rewrite it. Don't ship a doc that talks about a thing that no longer exists.

The most common drift sources:

- Refactoring `core/` without touching docs — base classes change, doc still describes the old API.
- Renaming a route — `RoutePaths.X` references stale.
- Adding a module without updating `service_locator.dart` AND the docs that enumerate modules.
- Editing a widget's constructor — doc still shows the old signature.

### 8. Keep harness lean

Every `.md` here is loaded into prompt context — noise costs tokens and dilutes signal.

When adding content: ask "does this change agent behaviour?" If no, cut it. Examples of behaviour-changing content: a rule, a real API surface, a decision matrix. Examples of fluff: marketing language, restating the obvious, listing every method the framework provides.

When editing: trim before you append. The depth layer (`docs/`) is allowed to be long because it loads on demand; `CLAUDE.md` itself stays as tight as practical.

### 9. Explain before bulk edits

Multi-concern file rewrites — refactoring a service, restructuring a BLoC, mass-renaming, big doc syncs — require a written plan FIRST. State:

- What files will be touched.
- What the change shape is per file ("rename method, update three call sites, add a new param with default").
- What you'd verify after.

Then wait for explicit direction. The user might want a smaller diff, a different sequence, or a hands-off file flagged. Surface > silent.

### 10. Prefer subagent dispatch — STRICT, always

Whenever a task matches an entry in the Sub-agent catalog below, the main agent MUST dispatch that subagent — **before plan, during plan, after plan, every time**. The main agent handles a task directly ONLY when:

- (a) no catalog entry fits the task (e.g. high-level system design, cross-step orchestration, conversational Q&A), or
- (b) the user explicitly says "do it yourself" / "don't use a subagent".

"I'll just write this small bit myself" after a plan exists = violation. Dispatch the named executor for each plan step.

#### Sub-agent catalog

| Task shape | Agent |
|---|---|
| Vague goal, multiple approaches possible, no decision yet | `brainstormer` |
| File-level implementation plan before any writing | `planner` |
| Audit the current git diff against rules + correctness | `reviewer` |
| Bug, failing test, unexpected behaviour — root cause first | `debugger` |
| Factual Q&A about the codebase with `file:line` citations | `researcher` |
| Stateless view from a requirement / design / Pencil data | `ui-ux-designer` |
| Scaffold a new module or add an API endpoint to an existing one | `feature-builder` |
| Write unit / widget / integration tests | `tester` |
| Edit `.claude/rules/`, `.claude/skills/`, `.claude/agents/`, or `docs/<NN>-*.md` | `docs-writer` |

Agent definitions live in `.claude/agents/<name>.md`.

#### Parallel by default

Independent agent calls go in ONE message with multiple `Agent` blocks. Sequential only when a later step depends on an earlier agent's output.

#### Rationale

- **Specialization** — each agent's prompt is scoped to one job; quality of output is higher than a generic main-agent attempt.
- **Token economy** — agents return a synthesized summary; raw `Read` / `Grep` / `Bash` output stays out of the main conversation.
- **Parallelism** — N independent agents finish in roughly the time of the slowest one.
- **Context protection** — the main agent's window is the most expensive context in the session; offloading work to subagents keeps it clean for orchestration.

#### Common slip — doing it inline because "it's faster"

It rarely is, once you count the context cost. Dispatch first; only reach for inline tools when the agent catalog genuinely doesn't fit.

## Hands-off protocol

When a task seems to require touching a hands-off file (see `01-architecture.md` § Hands-off boundary):

### 1. Pause

Don't edit silently. Don't sneak the edit into a PR labelled something else.

### 2. Surface the need

Explain WHAT, WHY, with 2-3 alternative paths:

> "To support automatic logout on 403, `AuthInterceptor` would need to clear tokens + signal the guard. This requires modifying `lib/core/network/interceptors/auth_interceptor.dart`, which is a hands-off file.
>
> Three options:
> 1. Add 403-handling directly to `AuthInterceptor` (modifies the hands-off file).
> 2. Add a new `ForbiddenInterceptor` sibling and register it in `ApiClient`'s interceptor list (touches `api_client.dart` — also hands-off, but smaller surface).
> 3. Handle 403 at the BLoC layer in `AuthBloc` — detect `ForbiddenException` from any usecase, dispatch a logout event. No foundation changes, but every BLoC that calls protected APIs has to remember.
>
> I recommend (3) for cohesion. Approve?"

### 3. Wait for approval

Only after the user explicitly says yes. Don't take silence as consent.

### Why this matters

Hands-off files are foundation — every module depends on them. A change here:

- Forces re-testing every consumer (every service, every interceptor user, every storage caller).
- Was designed deliberately — `_unwrap`'s envelope shape, `AuthInterceptor`'s single-flight refresh, `LocalStorage`'s mixed-backend interface — changes need design review, not just code review.
- Can't have its downstream effects predicted by AI agents without reading every consumer.

The hands-off list is in `CLAUDE.md` § Critical rules rule 9 + `01-architecture.md` § Hands-off boundary.

## Harness sync rule (principle 7, in detail)

Whenever any of these change in the codebase, the harness MUST update in the same PR:

| Change | Touch |
|---|---|
| File added / renamed / removed in `lib/core/` or `lib/app/` | `CLAUDE.md` architecture map + relevant `docs/<NN>-*.md` |
| Public API change on `ApiClient`, `LocalStorage`, `UseCase` base | `docs/04-networking.md` or `docs/05-clean-architecture.md` or `docs/08-platform.md` |
| New shared widget or token | `docs/07-theming-ui.md` § Shared widgets / § Tokens |
| New module added | `docs/00-overview.md`'s tree + `docs/01-architecture.md`'s sample structure (if illustrative) + `docs/06-modules.md` |
| Critical rule clarified / changed | `CLAUDE.md` § Critical rules + the doc the rule lives in |
| New dependency in `pubspec.yaml` | `docs/08-platform.md` § Dependencies |
| Bootstrap order changed in `main.dart` | `docs/01-architecture.md` § Bootstrap order |

Failure to sync = the doc lies to future agents and humans. Working principle 7 makes this a hard gate.

## How agents should approach a task

1. **Read `CLAUDE.md`** — already in context.
2. **Identify the relevant docs** — `CLAUDE.md`'s table maps topic → doc. Pull the right one(s).
3. **Read the relevant code** — the docs reference real files. Open them. Confirm the doc isn't stale.
4. **If the doc is stale**, surface — "Doc says X, code says Y. Fix code or fix doc?"
5. **Plan**, verify with user if scope is non-trivial.
6. **Implement**, one task at a time.
7. **Verify** — analyze, format, test, regenerate freezed.
8. **Sync harness** — if you touched anything the docs claim, update the docs.

## Common harness pitfalls

- **Silent edit to a hands-off file** — surfaces issue late, forces re-review of every consumer. Surface FIRST.
- **Doc drift after a refactor** — code says one thing, doc says another. Always sync in the same PR.
- **Inventing APIs** — `AppButton(isLoading: true)`, `Validators.confirmPassword`, etc. Read the source.
- **Adding content to `CLAUDE.md` that doesn't change agent behaviour** — noise. Trim before append.
- **Adding a doc for a sub-topic that should live inside an existing doc** — splitting prematurely fragments the depth layer. Add a section first; split when one doc is unwieldy.
- **Skipping the verify step** — "looks good" is not a verification. Run analyze + format + test.

## See also

- `00-overview.md` — project intro + harness layout summary
- `01-architecture.md` — folder layout, hands-off boundary
- `02-conventions.md` — code conventions, fpdart Either, codegen rules
- `CLAUDE.md` — always-loaded master (critical rules + working principles + indexes)
- `06-modules.md` — feature build flow
- `pubspec.yaml`, `analysis_options.yaml` — verifiable ground truth for deps + lint config

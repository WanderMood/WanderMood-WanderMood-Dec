# WanderMood — Restructure, lighten, and ~300-line file discipline

**Status:** **Phase A (§2) done** — `docs/LIB_LOC_REPORT.md` + `docs/ROUTER_MAP.md` + `scripts/lib_loc_report.sh`. **Step 2 in progress** — Explore: advanced filters in `explore_screen_af_*.part.dart`; **map view** in `explore_screen_map_view.part.dart` (~293 lines). Next slices: list/grid body, header/slivers, or sheets (`explore_screen.dart` still P0).  
**Goal:** Lighter, more maintainable, scalable codebase; **~300 lines per file** where reasonable (with explicit exceptions).  
**Constraint:** Do **not** break existing behaviour; no blind optimization; respect **frozen / sensitive flows** (see §8).

---

## 0. Reality check — what “266k lines” actually is

Before chasing line counts, align on **what counts** toward “heaviness”:

| Bucket | Rough scale (from prior audit) | Notes |
|--------|--------------------------------|--------|
| **`lib/l10n/*.dart`** | ~86k | **Codegen** from ARB (5 locales + delegate). Not hand-written UI. **Do not “refactor” by hand** — fix ARB + codegen. |
| **`*.freezed.dart` / `*.g.dart`** | ~26k | **Codegen** — normal for Freezed/JSON. |
| **Hand-maintained `lib/` (excl. l10n + generated)** | ~150k+ | This is where **structure, splits, and dead-code** work pay off. |

**Policy clarification:** “~300 lines” should apply to **widgets, screens (shell), notifiers, and services you maintain** — **not** to generated files, and **not** as a hard cap on **total feature LOC** spread across many files.

---

## 1. Guiding principles

1. **Thin screens, fat is OK if distributed** — A `*Screen` builds layout + delegates; heavy logic lives in `*Controller` / `*Notifier` / `*Service` / child widgets.
2. **One reason to change per file** — UI vs navigation vs data fetch vs analytics should not all churn in one file.
3. **Feature-first** — Explore, Moody, My Day, Places, Group planning, etc. each own `presentation/`, `application/` or `providers/`, `data/`, `domain/` as already partially done; **complete** the split for giants only.
4. **Preserve product behaviour** — Refactor = move code, same inputs/outputs; characterise with tests or manual scripts **before** large cuts.
5. **Respect frozen zones** — Do not rewrite working pipelines listed in §8 without explicit approval.

---

## 2. Phase A — Guardrails (before moving or splitting)

| # | Action | Outcome |
|---|--------|---------|
| A1 | **Baseline** — `flutter analyze`, `flutter test`, release smoke on iOS/Android. | Known-good reference (run locally before/after each refactor batch). |
| A2 | **Line report** — Script or doc: per-file LOC for `lib/**/*.dart` excluding `l10n`, `*.g.dart`, `*.freezed.dart`. | **`scripts/lib_loc_report.sh`** + snapshot **`docs/LIB_LOC_REPORT.md`**. |
| A3 | **Router map** — Document `go_router` routes → screen widgets. | **`docs/ROUTER_MAP.md`** (`lib/core/router/router.dart` is the only `GoRoute` source). |
| A4 | **“Do not touch” list** — From `.cursorrules` + `.cursor/rules` (auth, splash, `main()` order, frozen image/blurb files). | Shared team contract — see plan **§8** + `.cursor/rules/preserve-existing-flows.mdc`. |

---

## 3. Step 1 — Unused code (safe first) → `unused_files_review/`

**Intent:** Isolate candidates that are **not imported** and **not required for `flutter run`**, without deleting.

### 3.1 Alignment with **`Not-In-Use/`** (decision)

Step 1 candidates go under **`Not-In-Use/`** (Dart orphans / analyzer-excluded sources) with **`Not-In-Use/MANIFEST_STEP1.md`**. **Non-`lib/`** scaffolding mistakes and similar clutter may additionally be staged under **`unused_files_review/`** (see `unused_files_review/MANIFEST.md`) so the active tree stays minimal; both areas are **move-only**, no deletes.

### 3.2 Discovery process (repeatable)

1. **Static:** `dart analyze` + custom grep for `package:wandermood/...` imports from `lib/`.
2. **Entry graph:** From `lib/main.dart` + `lib/app.dart` + `lib/core/router/`, BFS/DFS reachable imports (script or IDE) — files **not reachable** are candidates (still **REVIEW**: `go_router` string paths, `dynamic` imports, tests, codegen).
3. **Already analyzer-excluded** — `analysis_options.yaml` `exclude:` entries are strong **“legacy / do not compile”** signals — candidates for `unused_files_review/` **after** confirming no runtime reference.
4. **Tests:** Unused **test** files — move to `unused_files_review/tests_mirror/…` only if sure no CI runs them.

### 3.3 Move rules

- **Move**, do not delete.
- **One PR / one feature area** per batch (e.g. “orphan plans widgets”) for easier revert.
- After each batch: **`flutter run` + critical path smoke** (login, Explore, My Day, place detail).

### 3.4 Exit criteria for permanent delete

- Lived in `unused_files_review/` for N days / N releases.
- Grep + CI green; no rollback needed.

---

## 4. Step 2 — Refactor large files (active code)

### 4.1 Priority queue (highest impact first)

Order by **(lines in hand-maintained Dart) × (change frequency / bug surface)**. Initial candidates from earlier audit:

| Priority | File (example) | ~Lines | Split strategy (high level) |
|----------|----------------|--------|-----------------------------|
| P0 | `explore_screen.dart` | ~4.8k | Map layer + sliver body + filter bar + grid/list + sheets → separate `presentation/widgets/explore_*` + `explore_controller.dart` / providers already partly there (`explore_screen_data.dart` — extend pattern). |
| P0 | `place_detail_screen.dart` | ~3.8k | Hero carousel / tabs / about / actions → tab widgets; photo resolution → existing service layer. **Respect frozen blurb/photo rules.** |
| P1 | `dynamic_my_day_screen.dart` | ~3.3k | Timeline vs sheets vs execution cards → widgets + notifier. |
| P1 | `redesigned_moody_hub.dart` | ~2.7k | Sections as `MoodyHub*Section` widgets; copy/providers extracted. |
| P1 | Group planning `*_screen.dart` / `group_planning_repository.dart` | ~2.5–3.3k | Screen vs repository vs DTO mapping. |
| P2 | `moody_chat_sheet.dart`, `agenda_screen.dart`, `activity_detail_screen.dart`, large `place_card.dart` | ~1.5–2.1k | Same pattern: widget extraction + state class. |

**Target:** each **new** file **≤ ~300 lines** where possible; legacy files shrink until the **screen** file is a **thin composer** (~150–300 lines).

### 4.2 Mechanical extraction patterns

- **`build` methods** — If > ~80 lines, extract `Widget _buildX()` to **private file** `explore_map_stack.dart` or public `ExploreMapStack` in same feature folder.
- **Callbacks / closures** — Long `onPressed` → named method or small widget.
- **Lists of widgets** — `Column(children: [ ... 40 items ])` → `ListView` of data-driven rows or sub-widgets.
- **Business rules** — Pure functions in `domain/` or `application/` with tests.
- **Side effects** — `ref.read(service)` in notifiers, not buried 200 lines deep in `build`.

### 4.3 What “300 lines” does **not** mean

- Splitting into 50 tiny one-liner files (worse maintainability).
- Touching **`lib/l10n/`** by hand (regenerate from ARB).
- Inlining **generated** code.

---

## 5. Step 3 — Architecture (scalable feature structure)

### 5.1 Target shape (per feature, e.g. `explore` under `home` or future top-level `explore/`)

```
feature_x/
  presentation/
    screens/           # thin: compose only
    widgets/           # reusable UI chunks
    sheets/            # optional
  application/         # or providers/ — orchestration, Riverpod notifiers
  domain/              # entities, value objects (optional)
  data/                # repositories, DTOs, API
```

### 5.2 Cross-cutting

- **`lib/core/`** — Router, theme, network, shared widgets, errors only.
- **Navigation** — Single source (`go_router`); no duplicate route constants in features (where possible).
- **Telemetry / analytics** — Thin adapter in `core/` or `application/`, not copy-pasted in every screen.

### 5.3 Performance (paired with structure)

- **List performance** — `ListView.builder` / slivers; avoid rebuilding huge subtrees (`Consumer` granularity).
- **Image pipeline** — Keep using **`WmPlacePhotoNetworkImage`** / existing URL helpers (**do not fork** per screen).
- **Debouncing** — Search/map updates already scattered; centralise per feature after split.

---

## 6. Risks and dependencies

| Risk | Mitigation |
|------|------------|
| **Breaking navigation** | Router-only PRs; grep `GoRoute` / path strings after moves. |
| **Riverpod provider scope** | Moving files changes import paths only if `part` / wrong barrel; move + `dart fix` + analyze. |
| **Merge conflicts** | One giant file split = high conflict; **vertical slice** PRs (e.g. “Explore map only”). |
| **Regressions in Explore / My Day** | Characterise with **widget tests** or golden tests **incrementally** on extracted widgets. |
| **Frozen files** (§8) | Refactor **callers** around them, not internals. |
| **Auth / splash / `main()`** | Per project rules: **no drive-by changes** — separate explicit task + QA. |

---

## 7. Suggested rollout order (phased)

| Phase | Scope | Deliverable |
|-------|--------|-------------|
| **0** | Guardrails §2 | Baseline + LOC report + route map → **see `docs/LIB_LOC_REPORT.md`, `docs/ROUTER_MAP.md`, `scripts/lib_loc_report.sh`** |
| **1** | `unused_files_review/` + `Not-In-Use/` | MANIFEST + smoke test (move-only; no deletes) |
| **2** | Explore split (P0) | Thin `explore_screen.dart` + N widgets; behaviour unchanged |
| **3** | Place detail split (P0) | Tabs/hero isolated; frozen paths untouched |
| **4** | My Day + Moody hub (P1) | Same pattern |
| **5** | Group planning (P1) | Repository vs UI separation |
| **6** | Sweep remaining >500-line files | LOC dashboard under budget |

Between phases: **release branch** or **TestFlight** soak if possible.

---

## 8. Do not change without explicit product approval

(From repo rules — summarise for refactor work.)

- **`main()`** startup order, **splash**, **auth / magic link**, **`GoRouter` redirects** — diagnose-only unless task says change.
- **Frozen:** `wm_network_image.dart`, `google_place_photo_device_url.dart`, `places_new_photo_resolver.dart`, `place_gallery_merge.dart` — **no** URL/image refactors.
- **Frozen card/blurb pipeline files** — do not “clean up” content rendering stack unless task requires it.
- **Supabase Edge** — deploy workflow: user merges/deploys; plan refactors in **Dart client** first.

---

## 9. Success metrics

| Metric | Target |
|--------|--------|
| Hand-maintained Dart LOC | Down over time (track monthly); **not** counting l10n/codegen |
| Files **> 500 lines** (excl. generated) | Trend to **zero** |
| Files **> 300 lines** | Justified list documented in PR |
| `flutter analyze` | Clean or agreed debt |
| Crash-free / critical smoke | No regression vs Phase 0 baseline |

---

## 10. Next implementation steps (current)

1. ~~**Phase 0 guardrails**~~ — LOC script + snapshot + router map (**done**; refresh `docs/LIB_LOC_REPORT.md` after large splits).  
2. **Phase 2 (P0)** — **Explore** vertical slice only: map stack **or** sliver body **or** filter bar **or** sheets — one PR-sized chunk; keep **`router.dart` / `main()` / auth** unchanged unless explicitly in scope.  
3. **Phase 3 (P0)** — **`place_detail_screen.dart`** splits; **do not** edit frozen image / blurb pipeline files (§8).  

**This document remains the contract** for scope, frozen zones, and file-size discipline.

---

*End of plan.*

# WanderMood redesign — QA status (active codebase)

**Scope:** Non-archived Dart under `lib/` only. Paths **not** modified: `**/archive/**`, `**/archived/**`, `**/archived_home_screens/**`.

## Done in this pass

| Checklist item | Status |
|----------------|--------|
| Toast notifications (custom overlay, not `SnackBar`) | **Done** — all live `ScaffoldMessenger`/`SnackBar` usages in active `lib/` replaced with `showWanderMoodToast`; remaining matches are **commented** code only. |
| `showWanderMoodToast` | Supports `isError`, `isWarning` (wmSunset), optional **action** label + callback (e.g. “View” → My Day). |
| Neon / legacy greens `#12B347`, `#16A34A` | **Replaced with wmForest `#2A6049`** across the touched settings, support, social, places, plans, profile, theme, and `app_theme` seed color (plus ui-avatars URL param). |
| `PlanConfirmationScreen` | **Fixed analyzer errors:** removed broken imports to missing `main_home_screen.dart`; `_buildActionButtons` now receives `WidgetRef ref`. |

## Previously addressed (earlier redesign work)

- Moody Hub, Explore, My Day hero, Place Detail, Profile stack, Agenda, review sheets, globe control borders, Material `shape` vs `borderRadius` crash on day hero buttons, etc.

## Not fully automated (honest scope)

These QA lines would require **broad refactors** across hundreds of widgets; they are **not** guaranteed line-by-line for every screen:

- Every screen background strictly `wmCream`
- No gradients except Globe
- All cards `wmWhite` + `wmParchment` 0.5px border + **no** `BoxShadow`
- Primary buttons exactly **54px** height everywhere
- Typography **only** the named wm text styles (every `fontSize` in the app)
- All padding/margin multiples of 4px everywhere

**Recommendation:** Treat the checklist as **design direction**; use tokens (`wmForest`, `wmCream`, …) for **new and touched** UI, and schedule dedicated UI audits per feature if you need strict compliance.

## Verify locally

```bash
dart analyze lib
flutter test
```

---

*Last updated: QA sweep (SnackBar → toast, neon green → wmForest, plan confirmation fix).*

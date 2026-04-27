# Hand-maintained `lib/` LOC snapshot

**Policy (from `REFACTOR_AND_STRUCTURE_PLAN.md` §0):** counts **exclude** `lib/l10n/**`, `*.g.dart`, and `*.freezed.dart` (codegen / ARB output).

**Regenerate:**

```bash
chmod +x scripts/lib_loc_report.sh   # once
./scripts/lib_loc_report.sh 35
```

**Captured:** 2026-04-26 (repo: `wandermood`). *Updated same day:* Explore map stack moved to `explore_screen_map_view.part.dart` — re-run the script for a fresh ranking.

## Top files by line count

| Lines | Path |
|------:|------|
| 3817 | `lib/features/places/presentation/screens/place_detail_screen.dart` |
| 3270 | `lib/features/home/presentation/screens/dynamic_my_day_screen.dart` |
| 3209 | `lib/features/home/presentation/screens/explore_screen.dart` |
| 3171 | `lib/features/group_planning/presentation/group_planning_result_screen.dart` |
| 2660 | `lib/features/home/presentation/screens/redesigned_moody_hub.dart` |
| 2533 | `lib/features/group_planning/data/group_planning_repository.dart` |
| 2467 | `lib/features/group_planning/presentation/group_planning_day_picker_screen.dart` |
| 2445 | `lib/features/home/presentation/screens/mood_home_screen.dart` |
| 2407 | `lib/features/group_planning/presentation/group_planning_lobby_screen.dart` |
| 2352 | `lib/features/home/presentation/widgets/moody_chat_sheet.dart` |
| 2222 | `lib/features/group_planning/presentation/group_planning_hub_screen.dart` |
| 2079 | `lib/features/plans/widgets/activity_detail_screen.dart` |
| 2016 | `lib/features/home/presentation/screens/agenda_screen.dart` |
| 1851 | `lib/features/home/presentation/screens/moody_conversation_screen.dart` |
| 1630 | `lib/features/profile/presentation/screens/edit_profile_screen.dart` |

*Also part of Explore (not in top-15 by LOC):* `explore_screen_map_view.part.dart` (~293 lines) — Google Map, markers, 1km / 4.5+ chips, `_getCityCoordinates` / `_calculatePlaceDistance`.

| Lines | Path |
|------:|------|
| 1569 | `lib/features/places/presentation/widgets/place_card.dart` |
| 1552 | `lib/features/places/presentation/screens/saved_places_screen.dart` |
| 1524 | `lib/features/weather/presentation/screens/weather_detail_screen.dart` |
| 1430 | `lib/features/places/providers/explore_places_provider.dart` |
| 1405 | `lib/features/plans/presentation/screens/day_plan_screen.dart` |
| 1310 | `lib/core/router/router.dart` |
| 1254 | `lib/features/mood/presentation/screens/check_in_screen.dart` |
| 1191 | `lib/features/profile/presentation/widgets/travel_mode_toggle.dart` |
| 1166 | `lib/features/profile/presentation/screens/user_profile_screen.dart` |
| 1150 | `lib/features/home/presentation/widgets/moody_action_sheet.dart` |
| 1138 | `lib/features/places/presentation/screens/collection_detail_screen.dart` |
| 1044 | `lib/features/group_planning/presentation/group_planning_reveal_screen.dart` |
| 1005 | `lib/features/profile/presentation/screens/share_profile_screen.dart` |
| 1004 | `lib/features/home/presentation/widgets/my_day_get_ready_sheet.dart` |
| 990 | `lib/core/services/google_places_service.dart` |
| 934 | `lib/features/mood/presentation/widgets/period_activities_bottom_sheet.dart` |
| 889 | `lib/core/services/wandermood_ai_service.dart` |
| 883 | `lib/features/auth/presentation/screens/magic_link_signup_screen.dart` |
| 861 | `lib/features/plans/presentation/widgets/day_plan_activity_card.dart` |

Use this list to drive **Step 2** splits in plan order: **Explore** → **Place detail** → My Day / Moody hub / group planning.

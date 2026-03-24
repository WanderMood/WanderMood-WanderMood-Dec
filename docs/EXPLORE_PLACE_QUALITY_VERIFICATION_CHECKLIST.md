# Explore Place Quality Verification Checklist

Use this after deploying the updated `moody` edge function and running cache reset.

## Preconditions

- `scripts/reset_places_cache_and_backfill.sql` executed successfully.
- Test user has valid location permission and non-mocked coordinates.
- Fresh app install or app cache cleared on test device.

## Acceptance Checks

1. Open Explore with 3 different moods.
2. Validate first 10 cards each mood:
   - has real place id
   - has photo
   - has rating and review count
   - has address
3. Tap a card in Explore:
   - place detail opens
   - photos + reviews + opening hours visible
4. Add same card to My Day.
5. Tap card in My Day:
   - opens same place detail screen (not fallback planner sheet)
6. Repeat from Agenda:
   - opens place detail screen for linked cards
7. Relaunch app and re-open Explore:
   - cached cards keep same quality fields

## Quick SQL Diagnostics

```sql
select count(*) as missing_place_id_count
from scheduled_activities
where place_id is null or trim(place_id) = '';

select count(*) as linked_place_id_count
from scheduled_activities
where place_id is not null and trim(place_id) <> '';
```

Expected: `missing_place_id_count` trends to near zero for newly scheduled data.

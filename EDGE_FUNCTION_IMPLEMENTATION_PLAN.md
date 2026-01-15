# Edge Function Implementation Plan - Complete Change List

## Overview
This document outlines ALL changes to be made to implement the `moody` Edge Function as the single source of truth for Explore, Day Plan, and Chat.

---

## PHASE 1: Database Schema Fixes (MUST BE FIRST)

### 1.1 Add `place_id` Column to `places_cache` Table

**File:** `supabase/migrations/add_place_id_to_places_cache.sql` (NEW)

**Changes:**
- Add `place_id TEXT` column to `places_cache` table
- Create index on `place_id` for fast lookups
- Backfill existing rows: Extract `place_id` from `data->>'place_id'` or `data->>'id'` JSONB field
- Update RLS policies if needed

**SQL Migration:**
```sql
-- Add place_id column
ALTER TABLE public.places_cache 
ADD COLUMN IF NOT EXISTS place_id TEXT;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_places_cache_place_id 
ON public.places_cache(place_id);

-- Backfill existing rows from JSONB data
UPDATE public.places_cache
SET place_id = COALESCE(
  data->>'place_id',
  data->>'id',
  data->'result'->>'place_id',
  data->'result'->>'id'
)
WHERE place_id IS NULL;

-- Make it NOT NULL after backfill (optional, can be nullable)
-- ALTER TABLE public.places_cache ALTER COLUMN place_id SET NOT NULL;
```

### 1.2 Verify `profiles.image_url` Column

**File:** `supabase/migrations/fix_missing_tables_and_columns.sql` (CHECK/UPDATE)

**Changes:**
- Verify `profiles.image_url` column exists
- If missing, add it
- Update all Flutter queries to use `image_url` consistently (remove `avatar_url` references if both exist)

**SQL Check:**
```sql
-- Check if column exists
SELECT column_name 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'profiles' 
  AND column_name = 'image_url';

-- If missing, add it:
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS image_url TEXT;
```

### 1.3 Update All Flutter Queries Using `places_cache`

**Files to Update:**
- `lib/features/places/application/places_service.dart`
- `lib/features/places/services/places_service.dart`
- `lib/features/plans/data/services/places_cache_service.dart`
- `lib/features/mood/presentation/screens/moody_hub_screen.dart` (if it queries places_cache)

**Changes:**
- Update all `places_cache` queries to include `place_id` in SELECT
- Update all INSERT statements to populate `place_id` column
- Remove any queries that try to access `place_id` from JSONB path if column now exists

---

## PHASE 2: Create Edge Function `moody`

### 2.1 Create Edge Function Structure

**New File:** `supabase/functions/moody/index.ts`

**Structure:**
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Verify auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Parse request body
    const { action, ...params } = await req.json()

    // 3. Route by action
    switch (action) {
      case 'get_explore':
        return await handleGetExplore(supabase, user.id, params)
      case 'create_day_plan':
        // TODO: Phase 3
        return new Response(JSON.stringify({ error: 'Not implemented' }), { status: 501 })
      case 'chat':
        // TODO: Phase 4
        return new Response(JSON.stringify({ error: 'Not implemented' }), { status: 501 })
      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

### 2.2 Implement `get_explore` Action Handler

**File:** `supabase/functions/moody/index.ts` (ADD FUNCTION)

**Function:** `handleGetExplore(supabase, userId, params)`

**Logic:**
1. Get user preferences from `profiles` table
2. Extract `mood`, `filters`, `location` from params
3. Check cache first (by `mood + location + filters_hash`)
4. If cache miss:
   - Fetch 30-60 places from Google Places API
   - Filter/rank by preferences (soft filtering, not hard)
   - Cache results in `places_cache` with `place_id` column populated
   - Return top 14+ cards
5. Always return >= 14 cards (use "popular nearby" fallback if filters too strict)

**Dependencies:**
- Google Places API key (from env: `GOOGLE_PLACES_API_KEY`)
- OpenAI API key (from env: `OPENAI_API_KEY`) - for ranking/context, not required for basic explore

**Response Format:**
```json
{
  "cards": [
    {
      "id": "google_ChIJ...",
      "name": "Place Name",
      "rating": 4.5,
      "types": ["restaurant", "food"],
      "location": { "lat": 51.9244, "lng": 4.4777 },
      "photo_reference": "...",
      "price_level": 2,
      "vicinity": "Rotterdam"
    }
  ],
  "cached": true,
  "total_found": 45
}
```

### 2.3 Environment Variables Setup

**File:** `.env.example` (UPDATE) or Supabase Dashboard

**Required Env Vars:**
- `GOOGLE_PLACES_API_KEY` - For fetching places
- `OPENAI_API_KEY` - For AI ranking/context (optional for Phase 2, required later)
- `SUPABASE_URL` - Auto-provided by Supabase
- `SUPABASE_ANON_KEY` - Auto-provided by Supabase

**Note:** Set these in Supabase Dashboard → Edge Functions → `moody` → Settings → Secrets

---

## PHASE 3: Update Flutter to Use Edge Function

### 3.1 Create Edge Function Service

**New File:** `lib/core/services/moody_edge_function_service.dart`

**Purpose:** Centralized service to call `moody` Edge Function

**Methods:**
- `getExplore({required String mood, Map<String, dynamic>? filters, required String location})`
- `createDayPlan(...)` - TODO Phase 3
- `chat(...)` - TODO Phase 4

**Implementation:**
```dart
class MoodyEdgeFunctionService {
  final SupabaseClient _supabase;

  MoodyEdgeFunctionService(this._supabase);

  Future<List<Place>> getExplore({
    required String mood,
    Map<String, dynamic>? filters,
    required String location,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'moody',
        body: {
          'action': 'get_explore',
          'mood': mood,
          'filters': filters ?? {},
          'location': location,
        },
      );

      if (response.data == null) {
        throw Exception('No data returned from Edge Function');
      }

      final cards = (response.data['cards'] as List)
          .map((card) => Place.fromJson(card))
          .toList();

      return cards;
    } catch (e) {
      throw Exception('Failed to get explore: $e');
    }
  }
}
```

### 3.2 Create Riverpod Provider for Edge Function

**New File:** `lib/features/places/providers/moody_explore_provider.dart`

**Purpose:** Replace `explorePlacesProvider` with Edge Function-based provider

**Implementation:**
```dart
final moodyExploreProvider = FutureProvider.family<List<Place>, ExploreParams>((ref, params) async {
  final service = MoodyEdgeFunctionService(Supabase.instance.client);
  return await service.getExplore(
    mood: params.mood,
    filters: params.filters,
    location: params.location,
  );
});

class ExploreParams {
  final String mood;
  final Map<String, dynamic>? filters;
  final String location;

  ExploreParams({
    required this.mood,
    this.filters,
    required this.location,
  });
}
```

### 3.3 Update Explore Screen

**File:** `lib/features/home/presentation/screens/explore_screen.dart`

**Changes:**
1. **Remove imports:**
   - `import 'package:wandermood/features/places/providers/explore_places_provider.dart';` (OLD)
   
2. **Add imports:**
   - `import 'package:wandermood/features/places/providers/moody_explore_provider.dart';` (NEW)
   - `import 'package:wandermood/core/services/moody_edge_function_service.dart';` (NEW)

3. **Replace provider usage:**
   - OLD: `ref.watch(explorePlacesProvider(city: currentCity))`
   - NEW: `ref.watch(moodyExploreProvider(ExploreParams(mood: currentMood, location: currentCity)))`

4. **Remove mock data generation:**
   - Remove any `_generateMockPlaces()` or similar functions
   - Remove fallback logic that creates fake places

5. **Update empty state handling:**
   - If Edge Function returns < 14 cards, show loading or retry
   - Edge Function should ALWAYS return >= 14 cards (fallback logic server-side)

6. **Comment out old provider logic:**
   - Keep `explorePlacesProvider` file but comment out usage
   - Mark with `// OLD - Replaced by moody_explore_provider`

### 3.4 Update Place Detail Screen

**File:** `lib/features/places/presentation/screens/place_detail_screen.dart`

**Changes:**
- Remove `explorePlacesProvider` import if used
- Update any place lookup to use Edge Function or direct cache query

### 3.5 Remove/Disable Old Explore Providers

**File:** `lib/features/places/providers/explore_places_provider.dart`

**Changes:**
- Add comment at top: `// DEPRECATED: Replaced by moody_explore_provider. Keep for 24-48h rollback safety.`
- Comment out the provider implementation
- Keep file for 24-48 hours, then delete

**File:** `lib/features/places/application/places_service.dart` (if used for explore)

**Changes:**
- Comment out explore-related methods
- Mark as deprecated

---

## PHASE 4: Testing & Validation

### 4.1 Acceptance Criteria Checklist

- [ ] **Zero Postgrest column errors** in logs
  - No `column places_cache.place_id does not exist`
  - No `column profiles.image_url does not exist`

- [ ] **Explore always shows >= 14 cards**
  - Test with different moods
  - Test with strict filters
  - Test with empty location

- [ ] **No mock/random data in Explore**
  - All places come from Edge Function
  - No hardcoded fallback places

- [ ] **Edge Function auth works**
  - Unauthenticated requests return 401
  - Authenticated requests work

- [ ] **Caching works**
  - First request: API call
  - Second request (same params): Cached response
  - Cache expires after 1 hour

- [ ] **Performance acceptable**
  - First load: < 3 seconds
  - Cached load: < 500ms

### 4.2 Test Scenarios

1. **New user after onboarding:**
   - Should land on Moody Hub (welcome overlay)
   - Explore should work without errors

2. **Explore with different moods:**
   - "adventurous" → should show adventure places
   - "relaxed" → should show relaxing places
   - "cultural" → should show cultural places

3. **Explore with filters:**
   - Price filter → should affect ranking
   - Distance filter → should affect ranking
   - Category filter → should affect ranking

4. **Edge Function failure:**
   - Network error → show error state
   - API error → show error state
   - Should NOT fall back to mock data

---

## PHASE 5: Cleanup (After 24-48 Hours)

### 5.1 Delete Commented Code

**Files to Clean:**
- `lib/features/places/providers/explore_places_provider.dart` (DELETE)
- Any commented-out mock data generation functions (DELETE)
- Old explore service methods (DELETE if unused)

### 5.2 Update Documentation

**Files to Update:**
- `README.md` - Document Edge Function architecture
- Add comments in code explaining Edge Function flow

---

## File Change Summary

### New Files (5)
1. `supabase/migrations/add_place_id_to_places_cache.sql`
2. `supabase/functions/moody/index.ts`
3. `lib/core/services/moody_edge_function_service.dart`
4. `lib/features/places/providers/moody_explore_provider.dart`
5. `EDGE_FUNCTION_IMPLEMENTATION_PLAN.md` (this file)

### Modified Files (6+)
1. `supabase/migrations/fix_missing_tables_and_columns.sql` (verify image_url)
2. `lib/features/places/application/places_service.dart` (update queries)
3. `lib/features/places/services/places_service.dart` (update queries)
4. `lib/features/plans/data/services/places_cache_service.dart` (update queries)
5. `lib/features/home/presentation/screens/explore_screen.dart` (replace provider)
6. `lib/features/places/presentation/screens/place_detail_screen.dart` (remove old provider)

### Deprecated Files (Delete after 24-48h)
1. `lib/features/places/providers/explore_places_provider.dart`

---

## Implementation Order

1. ✅ **Phase 1: Schema Fixes** (MUST BE FIRST)
   - Add `place_id` column
   - Verify `image_url` column
   - Update all queries

2. ✅ **Phase 2: Edge Function**
   - Create `moody` function skeleton
   - Implement `get_explore` action
   - Test locally with Supabase CLI

3. ✅ **Phase 3: Flutter Migration**
   - Create Edge Function service
   - Create new provider
   - Update Explore screen
   - Comment out old code

4. ✅ **Phase 4: Testing**
   - Test all scenarios
   - Verify acceptance criteria
   - Monitor logs for errors

5. ✅ **Phase 5: Cleanup**
   - Delete commented code
   - Update documentation

---

## Notes

- **No parallel logic:** Once Explore uses Edge Function, old logic is disabled
- **Safety net:** Keep old code commented for 24-48 hours
- **Cost:** Use `gpt-4o-mini` for explore/plan (cheaper)
- **Caching:** Aggressive caching (1 hour TTL) to reduce API calls
- **Fallback:** Edge Function should always return >= 14 cards (use "popular nearby" if filters too strict)

---

## Next Steps (Future Phases)

- **Phase 6:** Implement `create_day_plan` action
- **Phase 7:** Implement `chat` action with `moody_state` table
- **Phase 8:** Remove all remaining mock data from Day Plan and Chat

---

**Last Updated:** [Current Date]
**Status:** Ready for Implementation


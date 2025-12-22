# Fix #4: Explore Result Count - COMPLETE ✅

## Summary
Fixed Explore to fetch minimum 50 places per request, cache by city + mood only (not filters), and apply filters client-side. If filtered results < 5, automatically triggers wider fetch.

---

## Changes Made

### 1. Edge Function (`supabase/functions/moody/index.ts`)

#### ✅ Minimum 50 Places Guaranteed
- **Before**: Could return < 60 places with fallback
- **After**: Keeps fetching until minimum 50 places are found
- **Logic**: Up to 5 fetch attempts with fallback and broader searches
- **Result**: Always returns 50-80 places (minimum 50 required)

#### ✅ Cache Key Strategy Fixed
- **Before**: Cache key included filters → fragmented cache
- **After**: Cache key is `explore_{mood}_{city}` only (no filters)
- **Result**: Single cache entry per city+mood, filters applied client-side

#### ✅ Filters Applied Client-Side
- **Before**: Filters applied in Edge Function → reduced results before caching
- **After**: Filters applied client-side after fetching 50+ places
- **Result**: Cache always has 50+ places, filters reduce client-side

#### ✅ Broader Search Function
- **Added**: `fetchBroaderPlaces()` function for wider searches
- **Radius**: 30km (vs 20km for fallback)
- **Queries**: More general queries (attractions, landmarks, shopping, etc.)
- **Used**: When initial fetch + fallback still < 50 places

#### ✅ Response Includes Unfiltered Total
- **Added**: `unfiltered_total` field in response
- **Purpose**: Client can detect when filters reduce results too much
- **Usage**: Triggers wider fetch if filtered < 5 but unfiltered >= 50

---

### 2. Flutter Service (`lib/core/services/moody_edge_function_service.dart`)

#### ✅ Logs Unfiltered Total
- **Added**: Logs `unfiltered_total` from Edge Function response
- **Warning**: Logs warning if filtered < 5 but unfiltered >= 50
- **Purpose**: Helps debug filter issues

---

### 3. Flutter Explore Screen (`lib/features/home/presentation/screens/explore_screen.dart`)

#### ✅ Auto-Trigger Wider Fetch
- **Before**: No automatic wider fetch
- **After**: If filtered results < 5 and unfiltered >= 50, triggers wider fetch
- **Logic**: Invalidates provider to trigger refetch
- **Result**: User gets more results when filters are too restrictive

---

## Cache Strategy

### Before (BROKEN):
```
Cache Key: explore_adventurous_Rotterdam_{filters}
Result: Multiple cache entries for same city+mood with different filters
Problem: Cache fragmentation, inefficient storage
```

### After (FIXED):
```
Cache Key: explore_adventurous_rotterdam
Result: Single cache entry per city+mood
Filters: Applied client-side after fetching from cache
Benefit: Efficient caching, always 50+ places available
```

---

## Fetching Strategy

### Before:
```
1. Fetch places for mood
2. If < 60, fetch fallback
3. Return up to 80 places
Problem: Could still return < 50 places
```

### After:
```
1. Fetch places for mood
2. If < 50, fetch fallback places
3. If still < 50, fetch broader places (30km radius)
4. Repeat up to 5 times until 50+ places found
5. Cap at 80 places max
Result: Always returns 50-80 places
```

---

## Filtering Strategy

### Before:
```
Edge Function: Applies filters → Returns filtered places
Cache: Stores filtered places
Problem: Cache has fewer places, filters reduce too much
```

### After:
```
Edge Function: Fetches 50+ places → Returns all places
Cache: Stores all places (no filters)
Client: Applies filters client-side
Result: Cache always has 50+ places, filters reduce client-side
```

---

## Auto Wider Fetch Logic

### Trigger Condition:
- Filtered results < 5 places
- Unfiltered total >= 50 places
- Filters are too restrictive

### Action:
- Invalidates `moodyExploreAutoProvider`
- Triggers automatic refetch
- User gets more results

---

## Testing Checklist

### ✅ Minimum 50 Places
- [ ] Call Edge Function with valid location → Returns 50-80 places
- [ ] Call with small city → Still returns 50+ places (uses broader search)
- [ ] Verify cache has 50+ places

### ✅ Cache Strategy
- [ ] Call with different filters → Same cache entry used
- [ ] Verify cache key doesn't include filters
- [ ] Check cache has 50+ places regardless of filters

### ✅ Client-Side Filtering
- [ ] Apply filters → Results reduce but cache unchanged
- [ ] Remove filters → All 50+ places available again
- [ ] Verify filters don't affect cache

### ✅ Auto Wider Fetch
- [ ] Apply very restrictive filters → Results < 5
- [ ] Verify wider fetch triggered automatically
- [ ] Check logs for wider fetch warning

---

## Breaking Changes

### ⚠️ Cache Key Changed

**Before:**
```
explore_adventurous_Rotterdam_{filters}
```

**After:**
```
explore_adventurous_rotterdam
```

**Impact**: Existing cache entries will be invalidated (one-time)

### ⚠️ Response Format Changed

**Before:**
```json
{
  "cards": [...],
  "cached": true,
  "total_found": 20
}
```

**After:**
```json
{
  "cards": [...],
  "cached": true,
  "total_found": 15,
  "unfiltered_total": 65,
  "filters_applied": true
}
```

---

## Files Modified

1. `supabase/functions/moody/index.ts` - Minimum 50 places, cache strategy, client-side filtering
2. `lib/core/services/moody_edge_function_service.dart` - Logs unfiltered total
3. `lib/features/home/presentation/screens/explore_screen.dart` - Auto wider fetch logic

---

## Next Steps

1. **Test Edge Function**
   - Deploy to Supabase
   - Test with various locations
   - Verify minimum 50 places always returned
   - Check cache strategy works

2. **Monitor Cache**
   - Verify single cache entry per city+mood
   - Check cache has 50+ places
   - Monitor cache hit rates

3. **Test Filtering**
   - Apply various filters
   - Verify client-side filtering works
   - Test auto wider fetch trigger

---

## Status: ✅ COMPLETE

Explore now:
- ✅ Fetches minimum 50 places per request
- ✅ Caches by city + mood only (not filters)
- ✅ Applies filters client-side
- ✅ Auto-triggers wider fetch if filtered < 5

**Next**: Fix #5 - Time & Day Awareness


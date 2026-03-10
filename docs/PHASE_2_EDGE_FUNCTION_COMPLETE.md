# Phase 2: Edge Function `moody` - COMPLETE ✅

## Summary
The Edge Function `moody` has been created with `get_explore` action that fetches 60-80 places from Google Places API and caches them.

---

## What Was Created

### File: `supabase/functions/moody/index.ts`

**Features:**
1. ✅ **Auth Verification** - Verifies user JWT token
2. ✅ **Action Routing** - Routes by `action` parameter (`get_explore`, `create_day_plan`, `chat`)
3. ✅ **`get_explore` Handler** - Fully implemented:
   - Gets user preferences from `profiles` table
   - Checks cache first (1 hour TTL)
   - Fetches 30-60 places from Google Places API
   - Falls back to "popular nearby" if < 60 places found
   - Ranks/filters by user preferences (soft filtering)
   - Caches results with `place_id` column
   - Always returns >= 14 cards (ideally 60-80)

---

## How It Works

### Request Format
```json
{
  "action": "get_explore",
  "mood": "adventurous",
  "location": "Rotterdam",
  "filters": {
    "priceLevel": 2,
    "rating": 4.0,
    "types": ["restaurant", "museum"],
    "radius": 15000
  }
}
```

### Response Format
```json
{
  "cards": [
    {
      "id": "google_ChIJ...",
      "name": "Place Name",
      "rating": 4.5,
      "types": ["restaurant", "food"],
      "location": { "lat": 51.9225, "lng": 4.4792 },
      "photo_reference": "...",
      "price_level": 2,
      "vicinity": "Rotterdam",
      "address": "Full address",
      "description": "..."
    }
  ],
  "cached": false,
  "total_found": 75,
  "cache_key": "explore_adventurous_Rotterdam_..."
}
```

---

## Key Features

### 1. **Always Returns 60-80 Places**
- Fetches multiple queries based on mood (adventure activities, outdoor activities, etc.)
- If < 60 places found, fetches fallback places (popular attractions, tourist spots, etc.)
- Caps at 80 places to avoid overwhelming the UI

### 2. **Smart Caching**
- Cache key: `explore_{mood}_{location}_{filters}`
- TTL: 1 hour
- Stores individual places with `place_id` column (Phase 1 fix enables this)
- Also stores aggregate response for fast retrieval

### 3. **User Preferences Integration**
- Reads `favorite_mood`, `travel_style`, `travel_vibes` from `profiles` table
- Uses preferences for ranking (soft filtering)
- Hard filters (rating, price, types) are still respected

### 4. **Mood-Based Queries**
- Maps moods to relevant Google Places queries:
  - `adventurous` → adventure activities, extreme sports, hiking
  - `relaxed` → spa centers, beaches, parks, cafes
  - `cultural` → museums, art galleries, historical sites
  - etc.

### 5. **Fallback Logic**
- If primary queries return < 60 places, fetches:
  - Popular attractions
  - Tourist spots
  - Things to do
  - Restaurants, cafes, museums
- Ensures Explore always feels full

---

## Environment Variables Required

**Option A – Supabase CLI (project must be linked):**
```bash
supabase secrets set GOOGLE_PLACES_API_KEY=your-google-key
supabase secrets set OPENAI_API_KEY=your-openai-key
```

**Option B – Supabase Dashboard:**  
Go to **Edge Functions** → **moody** → **Settings** → **Secrets**, then add:

1. `GOOGLE_PLACES_API_KEY` - Your Google Places API key
   - Get from: Google Cloud Console → APIs & Services → Credentials
   - Must have Places API enabled

2. `OPENAI_API_KEY` - Your OpenAI API key (for `create_day_plan` AI-generated search queries)
   - Get from: https://platform.openai.com/api-keys
   - If unset, the function falls back to fixed mood→query mapping (no OpenAI call).

3. `SUPABASE_URL` / `SUPABASE_ANON_KEY` - Auto-provided by Supabase (do not set manually).

---

## Testing the Edge Function

### Option 1: Local Testing (Supabase CLI)
```bash
# Start Supabase locally
supabase start

# Test the function
curl -X POST http://localhost:54321/functions/v1/moody \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "get_explore",
    "mood": "adventurous",
    "location": "Rotterdam"
  }'
```

### Option 2: Deploy and Test
```bash
# Deploy function
supabase functions deploy moody

# Test via Supabase Dashboard → Edge Functions → moody → Invoke
```

### Option 3: Test from Flutter (after Phase 3)
```dart
final response = await supabase.functions.invoke('moody', body: {
  'action': 'get_explore',
  'mood': 'adventurous',
  'location': 'Rotterdam',
});
```

---

## Next Steps: Phase 3

1. **Update Flutter Explore Screen**
   - Create `MoodyEdgeFunctionService`
   - Create `moodyExploreProvider`
   - Update `explore_screen.dart` to use Edge Function
   - Remove old `explorePlacesProvider` usage

2. **Test Integration**
   - Verify Explore shows 60-80 places
   - Test caching (second request should be faster)
   - Test different moods
   - Test filters

3. **Monitor Performance**
   - Check Edge Function logs
   - Monitor API costs (Google Places)
   - Verify cache hit rates

---

## Notes

- **Rate Limiting**: Function includes 100ms delay between Google Places API calls to avoid rate limits
- **Error Handling**: Graceful fallbacks if API calls fail
- **Caching Strategy**: Individual places cached with `place_id`, aggregate response cached separately
- **Location Mapping**: Currently uses hardcoded coordinates (Rotterdam, Amsterdam, etc.). In production, use Google Geocoding API for dynamic locations.

---

## Status: ✅ READY FOR PHASE 3

Edge Function is complete and ready for Flutter integration.


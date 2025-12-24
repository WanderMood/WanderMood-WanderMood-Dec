# API Cache for Development Mode - Setup Guide

## Overview

This system caches Google Places API responses in Supabase to reduce API costs during development. In dev mode, the app uses cached data instead of making live API calls.

## How It Works

### Development Mode (Cost Savings)
1. **Check Cache First**: Before making any API call, check if cached data exists in Supabase
2. **Use Cache if Available**: If cached data exists and is valid, return it immediately (no API call)
3. **Skip API Calls**: If cache is missing, return empty results instead of making API calls
4. **Save Costs**: Zero API costs during development when using cached data

### Production Mode (Live Data)
1. **Check Cache First**: Still checks cache for performance
2. **Make API Calls**: If cache is missing, makes live API calls to Google Places
3. **Cache Results**: Automatically saves API responses to Supabase for future use

## Setup Instructions

### 1. Enable Dev Mode in Edge Function

Set the `DEV_MODE` environment variable in Supabase:

1. Go to Supabase Dashboard → Edge Functions → `moody` function
2. Go to Settings → Secrets
3. Add new secret:
   - **Key**: `DEV_MODE`
   - **Value**: `true` (for dev mode) or `false` (for production)

**OR** set `NODE_ENV` to `development`:

- **Key**: `NODE_ENV`
- **Value**: `development`

### 2. Populate Cache (One-Time Setup)

To populate the cache with initial data:

1. **Temporarily disable dev mode** (set `DEV_MODE=false` or `NODE_ENV=production`)
2. **Use the app normally** - make explore requests for different moods/locations
3. **API responses will be automatically cached** in Supabase
4. **Re-enable dev mode** (set `DEV_MODE=true`)
5. **Now all requests use cached data** - zero API costs!

### 3. Cache Management

#### View Cache Statistics

```dart
final stats = await SupabaseApiCacheService.getCacheStats();
print('Cache stats: $stats');
```

#### Clear Cache (if needed)

```dart
await SupabaseApiCacheService.clearAllCache();
```

## Cache Structure

### Supabase Table: `places_cache`

The cache is stored in the `places_cache` table with the following structure:

- `cache_key`: Unique identifier (e.g., `explore_adventurous_rotterdam`)
- `data`: JSONB containing the full API response
- `user_id`: User who made the request
- `request_type`: Type of request (`explore`, `search`, `details`, etc.)
- `query`: Search query (if applicable)
- `location_lat` / `location_lng`: Location coordinates
- `expires_at`: When the cache expires (default: 30 days)
- `created_at` / `updated_at`: Timestamps

## Cache Key Format

Cache keys are generated from:
- Endpoint name (e.g., `moody_explore`)
- Parameters (mood, location, coordinates)

Example: `explore_adventurous_rotterdam`

## Cost Savings

### Before (No Cache)
- Every explore request = ~$0.032 per request
- 100 requests/day = $3.20/day = ~$96/month

### After (With Cache)
- First request = $0.032 (cached)
- Subsequent requests = $0.00 (from cache)
- 100 requests/day = $0.00/day = $0/month (after initial cache)

**Savings: ~$96/month during development!**

## Switching Between Dev and Production

### Enable Dev Mode (Use Cache Only)
```bash
# In Supabase Dashboard → Edge Functions → moody → Settings → Secrets
DEV_MODE=true
# OR
NODE_ENV=development
```

### Enable Production Mode (Live API Calls)
```bash
# In Supabase Dashboard → Edge Functions → moody → Settings → Secrets
DEV_MODE=false
# OR
NODE_ENV=production
```

## Troubleshooting

### Issue: "No cached data available" in dev mode

**Solution**: Populate cache first:
1. Set `DEV_MODE=false` temporarily
2. Make a few explore requests
3. Set `DEV_MODE=true` again
4. Cache is now available

### Issue: Cache not being used

**Check**:
1. Is `DEV_MODE=true` set in Edge Function secrets?
2. Does cache entry exist in `places_cache` table?
3. Is cache expired? (check `expires_at` column)

### Issue: Want to refresh cache

**Solution**:
1. Clear old cache: `DELETE FROM places_cache WHERE cache_key LIKE 'explore_%';`
2. Set `DEV_MODE=false`
3. Make new requests to populate fresh cache
4. Set `DEV_MODE=true`

## Best Practices

1. **Populate cache before enabling dev mode** - Make a few requests in production mode first
2. **Cache different moods/locations** - Request data for various combinations you'll test
3. **Monitor cache expiration** - Cache expires after 30 days by default
4. **Use production mode for real testing** - Switch to production when testing new features that need live data

## Files Modified

- `supabase/functions/moody/index.ts` - Added dev mode check
- `lib/core/services/supabase_api_cache_service.dart` - New cache service
- `lib/core/services/moody_edge_function_service.dart` - Integrated cache service

## Next Steps

1. Set `DEV_MODE=true` in Supabase Edge Function secrets
2. Populate cache by making requests in production mode first
3. Switch back to dev mode and enjoy zero API costs! 🎉


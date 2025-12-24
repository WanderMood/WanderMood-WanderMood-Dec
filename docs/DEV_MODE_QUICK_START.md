# Dev Mode Quick Start Guide

## ✅ Step 1: Dev Mode Enabled
You've successfully set `DEV_MODE=true` in Supabase Edge Function secrets!

## 📦 Step 2: Populate Cache (One-Time Setup)

To populate the cache with initial data, you need to temporarily disable dev mode and make some API calls:

### Option A: Via Supabase Dashboard
1. Go to **Supabase Dashboard** → **Edge Functions** → **Settings** → **Secrets**
2. **Edit** the `DEV_MODE` secret
3. Change value from `true` to `false`
4. **Save**

### Option B: Keep Dev Mode ON (Recommended)
Actually, you can keep dev mode ON and just make requests. The Edge Function will:
- Check cache first (will be empty initially)
- Return empty results (no API costs)
- You can populate cache later when needed

## 🎯 Step 3: Populate Cache (When Ready)

When you're ready to populate cache with real data:

1. **Temporarily disable dev mode**:
   - Set `DEV_MODE=false` in Supabase Dashboard

2. **Make explore requests** in your app:
   - Open the app
   - Go to Explore screen
   - Select different moods (adventurous, relaxed, cultural, etc.)
   - Try different locations (Rotterdam, Amsterdam, etc.)
   - Each request will:
     - Make API calls to Google Places
     - Automatically cache the results in Supabase
     - Cost ~$0.032 per request

3. **Re-enable dev mode**:
   - Set `DEV_MODE=true` again
   - Now all future requests use cached data (zero cost!)

## 💰 Cost Savings

### Before Cache Population
- 10 explore requests = $0.32
- 50 explore requests = $1.60
- 100 explore requests = $3.20

### After Cache Population (Dev Mode ON)
- All requests = $0.00 (from cache)
- **Savings: 100% after initial setup!**

## 🔍 Verify It's Working

### Check Edge Function Logs
1. Go to **Supabase Dashboard** → **Edge Functions** → **moody** → **Logs**
2. Look for:
   - `🔧 Dev mode: ON (cache only)` ✅
   - `✅ Using cached explore results` ✅ (when cache exists)
   - `🚫 DEV MODE: Cache miss - returning empty results` ✅ (when cache missing)

### Check Cache in Database
1. Go to **Supabase Dashboard** → **Table Editor** → **places_cache**
2. You should see entries with:
   - `cache_key`: `explore_{mood}_{location}`
   - `data`: JSON with cached places
   - `expires_at`: Future date (30 days from creation)

## 🎉 You're All Set!

- **Dev mode is ON** → No API costs during development
- **Cache is ready** → Once populated, all requests use cached data
- **Production ready** → Just set `DEV_MODE=false` when deploying

## 📝 Quick Reference

### Enable Dev Mode
```
DEV_MODE=true
```

### Disable Dev Mode (Use Live API)
```
DEV_MODE=false
```

### Check Cache Stats (in Flutter)
```dart
final stats = await SupabaseApiCacheService.getCacheStats();
print('Cache stats: $stats');
```

## 🆘 Troubleshooting

### Issue: "No cached data available" message
**Solution**: Cache is empty. Either:
1. Populate cache by setting `DEV_MODE=false` temporarily
2. Or continue development with empty results (no API costs)

### Issue: Still making API calls
**Check**:
1. Is `DEV_MODE=true` set correctly in Edge Function secrets?
2. Did you redeploy the Edge Function after setting the secret?
3. Check Edge Function logs for dev mode status

### Issue: Want to refresh cache
**Solution**:
1. Set `DEV_MODE=false`
2. Make new requests to populate fresh cache
3. Set `DEV_MODE=true` again

---

**Next**: Start using the app! All explore requests will now use cached data (or return empty if cache is missing), saving you money during development! 🎉


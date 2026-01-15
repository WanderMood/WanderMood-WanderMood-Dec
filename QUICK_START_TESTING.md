# Quick Start: Testing Foundation Fixes

## ⚡ Immediate Next Steps (5 minutes)

### 1. Set API Key in Supabase (CRITICAL)

**Do this first - nothing will work without it!**

1. Go to: https://supabase.com/dashboard
2. Select your project
3. **Edge Functions** → **Settings** (or Project Settings → Edge Functions)
4. **Secrets** section → **Add Secret**
5. **Name**: `GOOGLE_PLACES_API_KEY`
6. **Value**: Your Google Places API key
7. **Save**

✅ **Verify**: You should see the secret in the list

---

### 2. Deploy Edge Functions

**Using Supabase CLI** (recommended):

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM

# Deploy moody function
supabase functions deploy moody

# Deploy wandermood-ai function
supabase functions deploy wandermood-ai
```

**Or using Dashboard**:
- Edge Functions → Select function → Deploy/Update

---

### 3. Quick Test

**Test in Flutter app**:

1. **Run the app**
2. **Enable location services** (Settings → Privacy → Location)
3. **Go to Explore screen**
4. **Check logs** for:
   - `🔑 API Key verified: AIzaSy...xxxx` ✅
   - `✅ Fetched X total places (minimum 50 required)` ✅
   - Photos display on place cards ✅

**If you see errors**:
- `❌ GOOGLE_PLACES_API_KEY not set` → Go back to Step 1
- `❌ Location is required` → Enable location services
- No photos → Check API key restrictions

---

## 🔍 How to Check if It's Working

### Check Supabase Logs

1. **Supabase Dashboard** → **Edge Functions** → **moody** → **Logs**
2. **Look for**:
   - ✅ `🔑 API Key verified` = API key is set correctly
   - ✅ `✅ Fetched X total places` = Places are being fetched
   - ❌ `❌ GOOGLE_PLACES_API_KEY not set` = Secret missing

### Check Flutter Logs

1. **Run app in debug mode**
2. **Check console/terminal**
3. **Look for**:
   - ✅ `✅ Edge Function returned X places` = Working
   - ✅ `✅ Using photo URL from Edge Function` = Photos working
   - ❌ `❌ Location is required` = Location issue

---

## 🎯 What to Test

### Quick Smoke Test (2 minutes)

1. ✅ **Explore Screen**: Should show 50+ places with photos
2. ✅ **Day Plan Generation**: Should create activities from Edge Function
3. ✅ **Moody Chat**: Should only reference real places

### Full Test (10 minutes)

See `TESTING_GUIDE_FOUNDATION_FIXES.md` for detailed test cases.

---

## 🚨 Common Issues

### "API Key not set"
**Fix**: Go to Supabase → Edge Functions → Settings → Secrets → Add `GOOGLE_PLACES_API_KEY`

### "Location is required"
**Fix**: Enable location services on device and grant permissions

### "No places found"
**Fix**: 
- Check location is valid city name
- Verify API key restrictions allow Supabase domains
- Check API quota in Google Cloud Console

### Photos don't load
**Fix**:
- Verify API key has "Places API" enabled
- Check Edge Function logs for `photo_url` in response
- Verify API key restrictions

---

## 📋 Pre-Production Checklist

Before going to production:

- [ ] API key set in Supabase secrets
- [ ] Edge Functions deployed
- [ ] API key restrictions configured (server + iOS bundle)
- [ ] Tested with real locations
- [ ] Photos display correctly
- [ ] Error states work properly
- [ ] Logs show API key verification
- [ ] Minimum 50 places returned
- [ ] Moody only references real places

---

## 🎉 You're Ready!

Once you've:
1. ✅ Set API key in Supabase
2. ✅ Deployed Edge Functions
3. ✅ Verified logs show API key verification

You can start testing! See `TESTING_GUIDE_FOUNDATION_FIXES.md` for detailed test cases.


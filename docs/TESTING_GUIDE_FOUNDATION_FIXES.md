# Testing Guide: Foundation Fixes

## 🚀 Supabase Setup (REQUIRED BEFORE TESTING)

### Step 1: Set Google Places API Key in Edge Function Secrets

**CRITICAL**: Without this, the Edge Function will fail.

1. **Go to Supabase Dashboard**
   - Navigate to your project: https://supabase.com/dashboard
   - Click on your project

2. **Go to Edge Functions Settings**
   - Click **Edge Functions** in left sidebar
   - Click **Settings** (or go to Project Settings → Edge Functions)

3. **Add Secret**
   - Find **Secrets** section
   - Click **Add Secret** or **+ New Secret**
   - **Name**: `GOOGLE_PLACES_API_KEY`
   - **Value**: Your Google Places API key (from Google Cloud Console)
   - Click **Save**

4. **Verify Secret Exists**
   - You should see `GOOGLE_PLACES_API_KEY` in the secrets list
   - Make sure it's enabled/active

### Step 2: Deploy Edge Functions

You need to deploy the updated `moody` and `wandermood-ai` Edge Functions:

#### Option A: Using Supabase CLI (Recommended)

```bash
# Make sure you're in the project root
cd /Users/edviennemerencia/WanderMood_july15th_9PM

# Deploy moody Edge Function
supabase functions deploy moody

# Deploy wandermood-ai Edge Function  
supabase functions deploy wandermood-ai
```

#### Option B: Using Supabase Dashboard

1. **Go to Edge Functions**
   - Click **Edge Functions** in left sidebar
   - Find `moody` function
   - Click **Deploy** or **Update**

2. **Upload Files**
   - You'll need to zip the function files and upload
   - Or use the CLI (easier)

### Step 3: Verify API Key in Logs

After deploying, check the logs:

1. **Go to Edge Functions → moody → Logs**
2. **Trigger a test request** (see testing steps below)
3. **Look for**: `🔑 API Key verified: AIzaSy...xxxx`
4. **If you see**: `❌ GOOGLE_PLACES_API_KEY not set` → Secret is missing

---

## 🧪 Testing Each Fix

### Fix #1: Location + Places API

#### Test 1.1: Location Required
**What to test**: Edge Function rejects requests without location

**Steps**:
1. Open Flutter app
2. Disable location services (Settings → Privacy → Location Services → OFF)
3. Try to use Explore screen
4. **Expected**: Error message "Location is required. Please enable location services..."

**Verify in Logs**:
- Edge Function logs show: `❌ Location is required but missing`
- Returns 400 status

#### Test 1.2: Photo URLs Work
**What to test**: Photos display correctly

**Steps**:
1. Enable location services
2. Go to Explore screen
3. Wait for places to load
4. **Expected**: Place cards show photos (not blank/placeholder)

**Verify**:
- Check Edge Function logs: `photo_url` field in response
- Check Flutter logs: `✅ Using photo URL from Edge Function`
- Photos actually display in UI

#### Test 1.3: API Key Verification
**What to test**: API key is properly configured

**Steps**:
1. Check Edge Function logs after any request
2. **Expected**: `🔑 API Key verified: AIzaSy...xxxx`

**If Missing**:
- Go to Supabase Dashboard → Edge Functions → Settings → Secrets
- Add `GOOGLE_PLACES_API_KEY` secret
- Redeploy Edge Function

---

### Fix #2: Edge Function as Only Data Authority

#### Test 2.1: Day Plan Generation Uses Edge Function
**What to test**: Activities come from Edge Function, not Flutter

**Steps**:
1. Go to mood selection screen
2. Select moods (e.g., "adventurous", "cultural")
3. Generate day plan
4. **Expected**: Activities load from Edge Function

**Verify in Logs**:
- Flutter: `🔗 Calling moody Edge Function: create_day_plan...`
- Edge Function: `🎯 create_day_plan: moods=..., location=..., coordinates=(...)`
- Edge Function: `✅ Generated X activities for day plan`

#### Test 2.2: No Fallback Generation
**What to test**: If Edge Function fails, shows error (not fake data)

**Steps**:
1. Disable location services
2. Try to generate day plan
3. **Expected**: Error dialog appears (not activities generated locally)

**Verify**:
- No Flutter logs about "fallback generation"
- Error dialog shows helpful message
- No activities displayed

#### Test 2.3: Empty State Handling
**What to test**: If no places found, shows structured empty state

**Steps**:
1. Use location with very few places (or mock API to return empty)
2. Try to generate day plan
3. **Expected**: Error message "No activities found for your selected moods..."

**Verify in Logs**:
- Edge Function: `⚠️ No places found for day plan - returning empty state`
- Response includes: `"success": false, "activities": []`

---

### Fix #3: Moody Must NOT Free-Text Recommend

#### Test 3.1: Moody Only References Real Places
**What to test**: Moody doesn't suggest places not in API results

**Steps**:
1. Go to Moody chat/interface
2. Ask: "What places do you recommend?"
3. **Expected**: Moody only mentions places from Explore results

**Verify**:
- Check Moody responses in logs
- Verify mentioned places exist in Explore results
- Moody doesn't mention "Witte de With" or other generic locations unless in results

#### Test 3.2: Empty State Message
**What to test**: If no places, Moody says "I don't have real options"

**Steps**:
1. Use location with no places (or mock to return empty)
2. Ask Moody for recommendations
3. **Expected**: Response: "I don't have real options for this right now..."

**Verify in Logs**:
- `wandermood-ai` Edge Function: `⚠️ No places found - returning empty state message`
- Response includes empty state message

#### Test 3.3: Moody Uses Real API Data
**What to test**: Moody gets places from moody Edge Function, not database

**Steps**:
1. Check `wandermood-ai` Edge Function logs
2. **Expected**: `🔍 Fetching places from moody Edge Function`
3. **Expected**: `✅ Retrieved X places from Google Places API via moody Edge Function`

**Verify**:
- No database queries for places
- Calls to `moody` Edge Function with `get_explore` action
- Places come from Google Places API

---

### Fix #4: Explore Result Count

#### Test 4.1: Minimum 50 Places
**What to test**: Explore always returns 50+ places

**Steps**:
1. Go to Explore screen
2. Wait for places to load
3. **Expected**: At least 50 places displayed

**Verify in Logs**:
- Edge Function: `✅ Fetched X total places (minimum 50 required)`
- Response includes: `"total_found": X` where X >= 50
- Response includes: `"unfiltered_total": X` where X >= 50

#### Test 4.2: Cache Strategy
**What to test**: Cache is by city + mood only (not filters)

**Steps**:
1. Load Explore with mood "adventurous"
2. Apply filters (rating, price)
3. Remove filters
4. **Expected**: Same places appear (from cache)

**Verify in Logs**:
- Edge Function: Cache key is `explore_adventurous_rotterdam` (no filters)
- First request: `🔄 Cache miss - fetching from Google Places API`
- Second request: `✅ Using cached explore results`

#### Test 4.3: Auto Wider Fetch
**What to test**: If filters reduce to < 5, triggers wider fetch

**Steps**:
1. Load Explore
2. Apply very restrictive filters (e.g., rating 5.0, specific type)
3. **Expected**: If results < 5, automatically refetches

**Verify in Logs**:
- Flutter: `⚠️ Filters reduced results to X places. Triggering wider fetch...`
- Provider invalidated and refetched

---

## 🔍 How to Check Logs

### Supabase Edge Function Logs

1. **Go to Supabase Dashboard**
2. **Edge Functions** → Select function (e.g., `moody`)
3. **Logs** tab
4. **Filter by**: Recent requests
5. **Look for**: Console.log messages with emojis (🔍, ✅, ❌, etc.)

### Flutter Logs

1. **Run app in debug mode**
2. **Check console/terminal** for debugPrint messages
3. **Look for**: Messages with emojis (📍, 🎯, ✅, ❌, etc.)

### Key Log Messages to Look For

**✅ Success Indicators**:
- `🔑 API Key verified: AIzaSy...xxxx`
- `✅ Fetched X total places (minimum 50 required)`
- `✅ Generated X activities for day plan`
- `✅ Retrieved X places from Google Places API via moody Edge Function`

**❌ Error Indicators**:
- `❌ GOOGLE_PLACES_API_KEY not set`
- `❌ Location is required but missing`
- `❌ Coordinates are required but missing`
- `⚠️ No places found - returning empty state`

---

## 🐛 Common Issues & Troubleshooting

### Issue 1: "GOOGLE_PLACES_API_KEY not set"

**Symptoms**:
- Edge Function logs show: `❌ GOOGLE_PLACES_API_KEY not set`
- No places returned
- Photos don't load

**Fix**:
1. Go to Supabase Dashboard → Edge Functions → Settings → Secrets
2. Add secret: `GOOGLE_PLACES_API_KEY` = your API key
3. Redeploy Edge Function: `supabase functions deploy moody`

### Issue 2: "Location is required"

**Symptoms**:
- Error message: "Location is required"
- Explore screen shows error state

**Fix**:
1. Enable location services on device
2. Grant location permissions to app
3. Or set location manually in app settings (if available)

### Issue 3: "No places found"

**Symptoms**:
- Empty Explore screen
- "No places found" message

**Possible Causes**:
- Location is invalid/unknown
- Google Places API key restrictions (check API key settings)
- API quota exceeded (check Google Cloud Console)

**Fix**:
1. Check location is valid city name
2. Verify API key restrictions allow Supabase Edge Function domain
3. Check API quota in Google Cloud Console

### Issue 4: Photos Don't Load

**Symptoms**:
- Place cards show no images
- Blank image placeholders

**Fix**:
1. Check Edge Function logs for `photo_url` in response
2. Verify API key has "Places API" enabled
3. Check photo URLs in response are valid
4. Verify API key restrictions allow photo requests

### Issue 5: Edge Function Returns < 50 Places

**Symptoms**:
- Explore shows fewer than 50 places
- Logs show: `⚠️ Only found X places`

**Possible Causes**:
- Location has very few places
- API quota/rate limiting
- Network issues

**Fix**:
1. Check Edge Function logs for fetch attempts
2. Verify API key quota not exceeded
3. Try different location with more places
4. Check if broader search is being triggered

---

## ✅ Verification Checklist

Before considering fixes complete, verify:

### Supabase Setup
- [ ] `GOOGLE_PLACES_API_KEY` secret is set in Edge Functions
- [ ] `moody` Edge Function is deployed
- [ ] `wandermood-ai` Edge Function is deployed
- [ ] Edge Function logs show API key verification

### Fix #1: Location + Places API
- [ ] Location is required (error if missing)
- [ ] Coordinates are required (error if missing)
- [ ] Photos display correctly
- [ ] API key verified in logs

### Fix #2: Edge Function Authority
- [ ] Day plan uses Edge Function (not Flutter generation)
- [ ] No fallback activity generation
- [ ] Empty state shows error (not fake data)
- [ ] Activities come from Google Places API

### Fix #3: Moody No Free-Text
- [ ] Moody only references places from API
- [ ] Empty state message if no places
- [ ] Moody uses moody Edge Function (not database)
- [ ] No generic location suggestions

### Fix #4: Explore Result Count
- [ ] Minimum 50 places returned
- [ ] Cache by city + mood only
- [ ] Filters applied client-side
- [ ] Auto wider fetch if filtered < 5

---

## 📝 Quick Test Commands

### Test Edge Function Directly (Optional)

You can test the Edge Function directly using curl or Postman:

```bash
# Test get_explore
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/moody \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "get_explore",
    "mood": "adventurous",
    "location": "Rotterdam",
    "coordinates": {
      "lat": 51.9225,
      "lng": 4.4792
    }
  }'

# Test create_day_plan
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/moody \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create_day_plan",
    "moods": ["adventurous"],
    "location": "Rotterdam",
    "coordinates": {
      "lat": 51.9225,
      "lng": 4.4792
    }
  }'
```

Replace:
- `YOUR_PROJECT` with your Supabase project reference
- `YOUR_ANON_KEY` with your Supabase anon key

---

## 🎯 Next Steps After Testing

1. **Monitor Logs**: Check Edge Function logs regularly for errors
2. **Verify API Usage**: Check Google Cloud Console for API usage/quota
3. **Test Edge Cases**: Test with various locations, moods, filters
4. **User Testing**: Have real users test the flow
5. **Performance**: Monitor response times and cache hit rates

---

## 🚨 Critical: Before Production

1. **API Key Restrictions**: Set proper restrictions in Google Cloud Console
   - Server restrictions: Supabase Edge Function domains
   - iOS bundle ID restrictions
   - API restrictions: Only "Places API" enabled

2. **Error Monitoring**: Set up error tracking
   - Monitor Edge Function error rates
   - Track location/permission errors
   - Monitor API quota usage

3. **Cache Strategy**: Monitor cache performance
   - Check cache hit rates
   - Verify cache expiration (1 hour)
   - Monitor cache storage

---

## 📞 Need Help?

If you encounter issues:

1. **Check Logs First**: Both Supabase and Flutter logs
2. **Verify Secrets**: Make sure API key is set in Supabase
3. **Test Edge Function**: Use curl/Postman to test directly
4. **Check API Key**: Verify in Google Cloud Console
5. **Review Error Messages**: They should be specific and helpful

---

## Status: Ready for Testing ✅

All fixes are complete. Follow the steps above to:
1. Set up Supabase (API key secret)
2. Deploy Edge Functions
3. Test each fix
4. Verify everything works

Good luck! 🚀


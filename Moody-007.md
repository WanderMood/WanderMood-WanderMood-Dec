# WanderMood — AI Agent Integration Prompt
## Complete Frontend ↔ Backend Specification

> **Purpose**: This document is the ground truth your AI coding agent needs to build,
> maintain, and extend the WanderMood frontend. Every table, endpoint, policy, and
> data shape is documented here. If the frontend does something that contradicts this
> document, the frontend is wrong.

---

## 1. PROJECT OVERVIEW

**WanderMood** is a mood-aware travel and activity discovery app. Users log their
current mood and energy level, and the app recommends activities and places that
match how they feel — powered by an AI assistant, location data, weather awareness,
and a preference-learning engine.

**Core user journey:**
1. User signs up → completes onboarding (preferences, mood profile)
2. User logs a mood check-in (mood + energy + optional notes)
3. App recommends activities and nearby places based on mood + preferences
4. User browses, saves, and schedules activities
5. User logs visited places and rates activities
6. AI assistant helps discover, plan, and reflect on experiences
7. Preference patterns are learned over time for better recommendations

---

## 2. SUPABASE CONNECTION

```
Project name:    WanderMood
Project ID:      oojpipspxwdmiyaymldo
Region:          eu-west-1 (Ireland)
Database:        PostgreSQL 17
Status:          ACTIVE_HEALTHY

SUPABASE_URL:    https://oojpipspxwdmiyaymldo.supabase.co
SUPABASE_ANON_KEY: [use your project anon key from Supabase dashboard → Settings → API]
```

**Initialize the client (TypeScript):**
```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)
```

**Environment variables required:**
```env
NEXT_PUBLIC_SUPABASE_URL=https://oojpipspxwdmiyaymldo.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
```

---

## 3. AUTHENTICATION

All auth is handled by Supabase Auth. The frontend MUST use Supabase Auth exclusively.

### Sign up
```typescript
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure-password',
})
// After sign-up, a trigger auto-creates a row in public.profiles
// Redirect user to onboarding after sign-up
```

### Sign in
```typescript
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password',
})
```

### Sign out
```typescript
await supabase.auth.signOut()
```

### Get current user
```typescript
const { data: { user } } = await supabase.auth.getUser()
// user.id is the UUID used as FK in all user tables
```

### Auth state listener (use in root layout)
```typescript
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT') router.push('/login')
  if (event === 'SIGNED_IN') router.push('/dashboard')
})
```

### Session persistence
```typescript
// Supabase JS v2 persists session in localStorage automatically
// For SSR (Next.js), use @supabase/ssr package
import { createServerClient } from '@supabase/ssr'
```

---

## 4. DATABASE TABLES

All 15 tables live in the `public` schema. RLS is enabled on all of them.

---

### 4.1 `profiles`
One row per user. Created automatically by a trigger on `auth.users` insert.

```sql
id                  uuid  PRIMARY KEY  → references auth.users.id
username            text  UNIQUE NOT NULL
full_name           text
email               text
bio                 text
image_url           text   -- profile photo URL (use this, NOT avatar_url — removed)
currently_exploring text   -- e.g. "Rotterdam", "Bali"
travel_style        text   -- default: 'adventurous'
travel_vibes        text[] -- e.g. ['Spontaneous', 'Social']
favorite_mood       text   -- default: 'happy'
interests           text[] -- e.g. ['food', 'art', 'hiking']
followers_count     int    -- default: 0
following_count     int    -- default: 0
posts_count         int    -- default: 0
is_public           bool   -- default: true
  -- When true, profile is visible to all users (including unauthenticated)
  -- When false, only the owner can see it
notification_preferences jsonb -- { "push": true, "email": true }
theme_preference    text   -- 'system' | 'light' | 'dark'
language_preference text   -- default: 'en'
achievements        text[] -- earned achievement slugs
mood_streak         int    -- consecutive days with check-in
date_of_birth       date
places_visited_count int   -- default: 0
created_at          timestamptz
updated_at          timestamptz
```

**RLS rules:**
- SELECT: owner always sees own profile; public profiles (`is_public = true`) visible to everyone
- INSERT: only own profile (`auth.uid() = id`)
- UPDATE: only own profile

**Fetch own profile:**
```typescript
const { data: profile } = await supabase
  .from('profiles')
  .select('*')
  .eq('id', user.id)
  .single()
```

**Fetch a public profile by username:**
```typescript
const { data: profile } = await supabase
  .from('profiles')
  .select('*')
  .eq('username', 'johndoe')
  .single()
// Returns null if profile is private and not the logged-in user
```

**Update profile:**
```typescript
const { error } = await supabase
  .from('profiles')
  .update({ full_name: 'Jane Doe', bio: 'Traveler', image_url: 'https://...' })
  .eq('id', user.id)
```

---

### 4.2 `user_preferences`
One row per user. Created during onboarding.

```sql
id                       uuid  PRIMARY KEY
user_id                  uuid  UNIQUE → auth.users.id
dark_mode                bool  default: false
use_system_theme         bool  default: true
use_animations           bool  default: true
show_confetti            bool  default: true
show_progress            bool  default: true
trip_reminders           bool  default: true
weather_updates          bool  default: true
mood_preferences         jsonb default: {}
travel_preferences       jsonb default: {}
activity_preferences     jsonb default: {}
communication_style      text  default: 'friendly'
interests                jsonb default: []
planning_pace            text  default: 'Same Day Planner'
  -- options: 'Same Day Planner' | 'Week Ahead Planner' | 'Spontaneous'
home_base                text  default: 'Local Explorer'
budget_level             text  default: 'Mid-Range'
  -- options: 'Budget' | 'Mid-Range' | 'Luxury'
language_preference      text  default: 'en'
has_completed_onboarding bool  default: false
has_completed_preferences bool default: false
selected_moods           jsonb default: []  -- moods user identifies with
travel_interests         jsonb default: []
social_vibe              jsonb default: []
travel_styles            jsonb default: []
favorite_moods           jsonb default: []
preferred_time_slots     jsonb default: ["morning","afternoon","evening"]
dietary_restrictions     jsonb default: []
mobility_requirements    jsonb default: []
age_group                text  -- '18-24' | '25-34' | '35-44' | '45-54' | '55+'
time_available           text  -- 'quick' | 'half-day' | 'full-day'
activity_pace            text  -- 'slow' | 'moderate' | 'fast'
created_at               timestamptz
updated_at               timestamptz
```

**RLS rules:** Full CRUD — owner only.

**Upsert preferences (use upsert to handle both create + update):**
```typescript
const { error } = await supabase
  .from('user_preferences')
  .upsert({
    user_id: user.id,
    has_completed_onboarding: true,
    selected_moods: ['happy', 'adventurous'],
    budget_level: 'Mid-Range',
  }, { onConflict: 'user_id' })
```

---

### 4.3 `moods`
Mood log entries. Each check-in can create a mood entry.

```sql
id              uuid  PRIMARY KEY
user_id         uuid  → auth.users.id
mood            text  NOT NULL  -- e.g. 'happy', 'tired', 'adventurous', 'calm'
activity        text            -- what user was doing when they logged this
energy_level    numeric(1-10)  -- 1=exhausted, 10=buzzing
notes           text
location        text            -- free-text location name
weather_condition text          -- e.g. 'sunny', 'rainy'
created_at      timestamptz
```

**RLS rules:** Full CRUD — owner only.

**Log a mood:**
```typescript
const { data, error } = await supabase
  .from('moods')
  .insert({
    user_id: user.id,
    mood: 'adventurous',
    energy_level: 8,
    notes: 'Feeling pumped after my morning run',
    location: 'Rotterdam',
    weather_condition: 'sunny',
  })
  .select()
  .single()
```

**Get mood history:**
```typescript
const { data: moods } = await supabase
  .from('moods')
  .select('*')
  .eq('user_id', user.id)
  .order('created_at', { ascending: false })
  .limit(30)
```

---

### 4.4 `user_check_ins`
Richer check-in entries (superset of moods — more metadata).

```sql
id          uuid  PRIMARY KEY
user_id     uuid  → auth.users.id
mood        text  NOT NULL
text        text            -- longer reflection or note
activities  text[]          -- list of activity slugs done
reactions   text[]  default: []  -- emoji reactions or tags
metadata    jsonb   default: {}  -- extensible extra data
created_at  timestamptz
```

**RLS rules:** Full CRUD — owner only.

**Create check-in:**
```typescript
const { data, error } = await supabase
  .from('user_check_ins')
  .insert({
    user_id: user.id,
    mood: 'calm',
    text: 'Had a slow morning, feeling reflective',
    activities: ['reading', 'coffee'],
    reactions: ['🌿', '☕'],
  })
  .select()
  .single()
```

---

### 4.5 `activities`
Seeded catalog of activity types (read-only for users).

```sql
id          uuid  PRIMARY KEY
name        text  NOT NULL
category    text            -- e.g. 'outdoor', 'food', 'culture', 'wellness'
description text
mood_tags   text[]          -- moods this activity suits, e.g. ['happy', 'energetic']
energy_level text           -- 'low' | 'medium' | 'high'
created_at  timestamptz
```

**RLS rules:** SELECT only — anyone can read.

**IMPORTANT: This table is currently empty.** The app must NOT crash if this table
returns zero rows. Fall back to AI-generated activity suggestions via the `moody`
edge function when this table is empty.

```typescript
const { data: activities } = await supabase
  .from('activities')
  .select('*')
  .contains('mood_tags', [currentMood])
  .eq('energy_level', 'medium')
```

---

### 4.6 `activity_ratings`
User reviews of activities they have completed.

```sql
id             uuid  PRIMARY KEY
user_id        uuid  → auth.users.id
activity_id    text  NOT NULL  -- can be a UUID from activities table OR a Google Place ID
activity_name  text            -- display name (denormalized for performance)
place_name     text            -- optional venue name
stars          int  (1-5)
tags           text[]          -- e.g. ['fun', 'romantic', 'kid-friendly']
notes          text
mood           text            -- mood when activity was done
would_recommend bool  default: false
completed_at   timestamptz
created_at     timestamptz
```

**RLS rules:** Full CRUD — owner only.

**Rate an activity:**
```typescript
const { error } = await supabase
  .from('activity_ratings')
  .insert({
    user_id: user.id,
    activity_id: 'ChIJ...googlePlaceId',
    activity_name: 'Kayaking at Kralingse Plas',
    stars: 5,
    tags: ['outdoor', 'fun', 'active'],
    notes: 'Great morning activity, the lake was perfect',
    mood: 'adventurous',
    would_recommend: true,
  })
```

---

### 4.7 `scheduled_activities`
Activities the user has planned for a future date/time.

```sql
id             int   PRIMARY KEY (auto-increment)
user_id        uuid  → auth.users.id
activity_id    text  NOT NULL       -- Google Place ID or internal activity UUID
name           text  NOT NULL
description    text
image_url      text
start_time     timestamptz NOT NULL
duration       int   NOT NULL       -- duration in minutes
location_name  text
latitude       float8
longitude      float8
is_confirmed   bool  default: false
tags           text               -- comma-separated or JSON string
payment_type   text  default: 'free'  -- 'free' | 'paid' | 'booking-required'
place_id       text               -- Google Place ID
rating         float8             -- Google Maps rating (for reference)
scheduled_date date
created_at     timestamptz
updated_at     timestamptz
```

**RLS rules:** Full CRUD — owner only.

**Schedule an activity:**
```typescript
const { data, error } = await supabase
  .from('scheduled_activities')
  .insert({
    user_id: user.id,
    activity_id: 'ChIJ...',
    name: 'Visit Markthal Rotterdam',
    start_time: '2026-03-25T10:00:00+01:00',
    duration: 90,
    location_name: 'Markthal, Rotterdam',
    latitude: 51.9201,
    longitude: 4.4862,
    payment_type: 'free',
  })
  .select()
  .single()
```

**Get upcoming schedule:**
```typescript
const { data: schedule } = await supabase
  .from('scheduled_activities')
  .select('*')
  .eq('user_id', user.id)
  .gte('start_time', new Date().toISOString())
  .order('start_time', { ascending: true })
```

---

### 4.8 `visited_places`
Places the user has been to, with mood context.

```sql
id           uuid  PRIMARY KEY
user_id      uuid  → auth.users.id
place_name   text  NOT NULL
city         text
country      text
lat          float8 NOT NULL
lng          float8 NOT NULL
mood         text            -- mood when visited
mood_emoji   text            -- e.g. '😊'
energy_level numeric(1-10)
notes        text
visited_at   timestamptz  default: now()
created_at   timestamptz
```

**RLS rules:** Full CRUD — owner only.

**Log a visited place:**
```typescript
const { error } = await supabase
  .from('visited_places')
  .insert({
    user_id: user.id,
    place_name: 'Euromast',
    city: 'Rotterdam',
    country: 'Netherlands',
    lat: 51.9050,
    lng: 4.4666,
    mood: 'happy',
    mood_emoji: '😊',
    energy_level: 7,
    notes: 'Amazing views from the top!',
  })
```

---

### 4.9 `user_saved_places`
Bookmarked/wishlist places.

```sql
id          uuid  PRIMARY KEY
user_id     uuid  → auth.users.id
place_id    text  NOT NULL      -- Google Place ID
place_name  text               -- display name
place_data  jsonb              -- full place object snapshot
saved_at    timestamptz  default: now()
```

**RLS rules:** Full CRUD — owner only.

**Save a place:**
```typescript
const { error } = await supabase
  .from('user_saved_places')
  .insert({
    user_id: user.id,
    place_id: 'ChIJN1t_tDeuEmsRUsoyG83frY4',
    place_name: 'Cube Houses Rotterdam',
    place_data: { rating: 4.5, types: ['tourist_attraction'], /* ... */ },
  })
```

**Check if a place is saved:**
```typescript
const { data } = await supabase
  .from('user_saved_places')
  .select('id')
  .eq('user_id', user.id)
  .eq('place_id', placeId)
  .single()
const isSaved = !!data
```

---

### 4.10 `ai_conversations`
Persistent chat history with the WanderMood AI assistant.

```sql
id              uuid  PRIMARY KEY
conversation_id text  NOT NULL   -- groups messages into threads (e.g. UUID you generate client-side)
user_id         uuid  → auth.users.id
role            text  NOT NULL   -- CHECK: 'user' | 'assistant' | 'system'
content         text  NOT NULL
created_at      timestamptz
```

**RLS rules:** SELECT + INSERT + DELETE — owner only. No UPDATE (messages are immutable).

**Send a message (save to DB):**
```typescript
// Save user message
await supabase.from('ai_conversations').insert({
  conversation_id: conversationId,
  user_id: user.id,
  role: 'user',
  content: userMessage,
})

// Call edge function (see section 5)
const aiResponse = await callMoodyFunction(conversationId, userMessage)

// Save assistant response
await supabase.from('ai_conversations').insert({
  conversation_id: conversationId,
  user_id: user.id,
  role: 'assistant',
  content: aiResponse,
})
```

**Load conversation history:**
```typescript
const { data: messages } = await supabase
  .from('ai_conversations')
  .select('role, content, created_at')
  .eq('user_id', user.id)
  .eq('conversation_id', conversationId)
  .order('created_at', { ascending: true })
```

**Delete a conversation:**
```typescript
await supabase
  .from('ai_conversations')
  .delete()
  .eq('user_id', user.id)
  .eq('conversation_id', conversationId)
```

---

### 4.11 `user_preference_patterns`
Machine-learned preference scores — updated by the backend as the user interacts.
The frontend reads this to personalize recommendations; do NOT write to this table
directly from the frontend (the `moody` edge function updates it).

```sql
id                    uuid  PRIMARY KEY
user_id               uuid  → auth.users.id  (UNIQUE — one row per user)
mood_activity_scores  jsonb  default: {}   -- { "happy:outdoor": 0.9, "tired:spa": 0.8 }
tag_counts            jsonb  default: {}   -- { "romantic": 3, "outdoor": 12 }
time_preferences      jsonb  default: {}   -- { "morning": 0.7, "evening": 0.3 }
top_rated_places      text[] default: []  -- Place IDs sorted by user rating
top_rated_activities  text[] default: []  -- Activity IDs sorted by rating
last_updated          timestamptz
```

**RLS rules:** SELECT + INSERT + UPDATE — owner only.

**Read patterns (for recommendation UI):**
```typescript
const { data: patterns } = await supabase
  .from('user_preference_patterns')
  .select('*')
  .eq('user_id', user.id)
  .single()
// Use patterns.top_rated_places to surface "Your favourites" section
// Use patterns.mood_activity_scores for mood-matched sorting
```

---

### 4.12 `places_cache`
Server-side cache of Google Places API results. The frontend reads from this cache
before making fresh API calls to save quota and improve speed.

```sql
id           uuid  PRIMARY KEY
cache_key    text  UNIQUE NOT NULL  -- deterministic key: e.g. "search:rotterdam:outdoor"
data         jsonb NOT NULL         -- full API response
user_id      uuid  (nullable) → auth.users.id  -- which user triggered the cache
request_type text  -- CHECK: 'search'|'autocomplete'|'details'|'photos'|'nearby'|'explore'
place_id     text  -- Google Place ID extracted from data
expires_at   timestamptz NOT NULL
created_at   timestamptz
```

**RLS rules:**
- SELECT: public (anyone can read cache)
- INSERT/UPDATE/DELETE: authenticated users only

**Check cache before API call:**
```typescript
const cacheKey = `search:${city}:${mood}:${category}`

const { data: cached } = await supabase
  .from('places_cache')
  .select('data')
  .eq('cache_key', cacheKey)
  .gt('expires_at', new Date().toISOString())  // not expired
  .single()

if (cached) return cached.data  // use cache hit
// else: call Google Places API, then write result to cache
```

---

### 4.13 `place_reviews_cache`
Cached review data for places.

```sql
place_id     text  PRIMARY KEY  -- Google Place ID
reviews      jsonb  default: []
last_updated timestamptz
expires_at   timestamptz NOT NULL
created_at   timestamptz
```

**RLS rules:**
- SELECT: anyone
- INSERT/UPDATE/DELETE: authenticated users only

---

### 4.14 `weather_cache`
Cached weather data keyed by location string.

```sql
id           uuid  PRIMARY KEY
location     text  UNIQUE NOT NULL  -- e.g. "Rotterdam,NL"
weather_data jsonb NOT NULL         -- OpenWeatherMap or similar API response
cached_at    timestamptz
expires_at   timestamptz NOT NULL
```

**RLS rules:**
- SELECT: anyone
- INSERT/UPDATE: authenticated users only

**Read weather:**
```typescript
const { data: weather } = await supabase
  .from('weather_cache')
  .select('weather_data')
  .eq('location', 'Rotterdam,NL')
  .gt('expires_at', new Date().toISOString())
  .single()
```

---

### 4.15 `gyg_links`
GetYourGuide affiliate booking links. Read-only for the frontend.

```sql
id          bigint  PRIMARY KEY
destination text    NOT NULL   -- city/destination name, e.g. "Rotterdam"
type        text    NOT NULL   -- category type, e.g. "tours", "activities"
url         text    NOT NULL   -- affiliate URL
is_active   bool
created_at  timestamptz
```

**RLS rules:** SELECT only — anyone can read.

**Fetch booking links for a destination:**
```typescript
const { data: links } = await supabase
  .from('gyg_links')
  .select('*')
  .eq('destination', 'Rotterdam')
  .eq('is_active', true)
```

---

## 5. EDGE FUNCTIONS

All edge functions are deployed at:
```
https://oojpipspxwdmiyaymldo.supabase.co/functions/v1/<slug>
```

---

### 5.1 `moody` — Main AI + Recommendation Engine
**JWT required: YES** — always send the user's auth token.

This is the primary AI function. It handles activity recommendations, chat,
preference learning, and anything that requires LLM reasoning.

```typescript
// Always get the session token first
const { data: { session } } = await supabase.auth.getSession()

const response = await fetch(
  'https://oojpipspxwdmiyaymldo.supabase.co/functions/v1/moody',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${session.access_token}`,  // REQUIRED
    },
    body: JSON.stringify({
      // Consult the moody function source for exact payload shape
      // Typical payload:
      mood: 'adventurous',
      energy_level: 8,
      location: { lat: 51.9244, lng: 4.4777 },
      conversation_id: 'uuid-here',
      message: 'What should I do this afternoon?',
      user_preferences: { budget_level: 'Mid-Range', travel_style: 'adventurous' },
    }),
  }
)

const data = await response.json()
// data.recommendations — array of place/activity suggestions
// data.message — AI text response
// data.conversation_id — echo of conversation_id
```

**NEVER call this function without the Authorization header.** It will return 401.

---

### 5.2 `wandermood_ai` — Secondary AI Endpoint
**JWT required: YES** ⚠️ (this was fixed — previously had no JWT check)

Use this only if `moody` does not handle a specific use case.
Prefer `moody` for all new frontend integrations.

```typescript
const response = await fetch(
  'https://oojpipspxwdmiyaymldo.supabase.co/functions/v1/wandermood_ai',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${session.access_token}`,  // NOW REQUIRED
    },
    body: JSON.stringify({ /* payload */ }),
  }
)
```

---

### 5.3 `delete-user` — Account Deletion (Primary)
**JWT required: YES**

Deletes the authenticated user's account and all associated data.

```typescript
const response = await fetch(
  'https://oojpipspxwdmiyaymldo.supabase.co/functions/v1/delete-user',
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
    },
  }
)
// On success: sign out and redirect to /goodbye
await supabase.auth.signOut()
router.push('/goodbye')
```

> **Note:** `delete_user_account` (v1) is a duplicate of this function and should
> NOT be called from the frontend. Use `delete-user` (v4) only.

---

## 6. REAL-TIME SUBSCRIPTIONS

Use Supabase Realtime for live updates where relevant.

**Live mood feed (if building social features):**
```typescript
const channel = supabase
  .channel('public-moods')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'moods',
    filter: `user_id=eq.${user.id}`,
  }, (payload) => {
    setMoods(prev => [payload.new, ...prev])
  })
  .subscribe()

// Clean up on unmount:
return () => supabase.removeChannel(channel)
```

**Live AI conversation:**
```typescript
const channel = supabase
  .channel(`conversation:${conversationId}`)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'ai_conversations',
    filter: `conversation_id=eq.${conversationId}`,
  }, (payload) => {
    setMessages(prev => [...prev, payload.new])
  })
  .subscribe()
```

---

## 7. ONBOARDING FLOW — EXACT SEQUENCE

The onboarding sequence is critical. Follow this exactly:

```
1. User signs up → auth.users row created
   ↓ (Supabase trigger fires automatically)
2. public.profiles row created with user.id
3. Frontend detects new user (check user_preferences.has_completed_onboarding = false)
4. Redirect to /onboarding
5. Step 1: Choose travel style + travel vibes → update profiles.travel_style, profiles.travel_vibes
6. Step 2: Choose moods → update user_preferences.selected_moods
7. Step 3: Choose travel interests → update user_preferences.travel_interests
8. Step 4: Set budget, pace, time → update user_preferences.budget_level, activity_pace, time_available
9. Step 5: Set age group, dietary restrictions, mobility → update user_preferences
10. Final step: upsert user_preferences with has_completed_onboarding = true
11. Redirect to /dashboard
```

**Check onboarding status on every page load:**
```typescript
const { data: prefs } = await supabase
  .from('user_preferences')
  .select('has_completed_onboarding, has_completed_preferences')
  .eq('user_id', user.id)
  .single()

if (!prefs || !prefs.has_completed_onboarding) {
  router.push('/onboarding')
}
```

---

## 8. DATA FLOW — MOOD-BASED RECOMMENDATION

```
User logs mood check-in
        ↓
INSERT into moods (user_id, mood, energy_level, ...)
INSERT into user_check_ins (user_id, mood, text, ...)
        ↓
Call moody edge function with:
  - current mood + energy
  - user_preferences (fetched from DB)
  - location coordinates
  - user_preference_patterns (top_rated_places, mood_activity_scores)
        ↓
moody returns recommendations[]
        ↓
Check places_cache for each recommendation:
  - Cache hit: use cached data
  - Cache miss: fetch from Google Places, write to places_cache
        ↓
Render activity cards to user
        ↓
User rates / saves / schedules activity
  → activity_ratings INSERT
  → user_saved_places INSERT
  → scheduled_activities INSERT
        ↓
moody function updates user_preference_patterns in background
```

---

## 9. ERROR HANDLING RULES

Every Supabase call can return an `error` object. NEVER ignore it.

```typescript
const { data, error } = await supabase.from('profiles').select('*').single()

if (error) {
  if (error.code === 'PGRST116') {
    // Row not found — handle gracefully (e.g. redirect to onboarding)
  } else if (error.code === '42501') {
    // RLS violation — user doesn't have access (sign them out)
    await supabase.auth.signOut()
  } else {
    // Unknown error — log and show user-friendly message
    console.error('Supabase error:', error.message)
    toast.error('Something went wrong. Please try again.')
  }
}
```

**Common error codes:**
- `PGRST116` — Row not found (`.single()` returned 0 rows)
- `23505` — Unique constraint violation (duplicate username, duplicate saved place)
- `42501` — RLS policy violation (forbidden)
- `23503` — Foreign key violation (user_id doesn't exist in auth.users)

---

## 10. TYPESCRIPT TYPES

Generate types directly from your Supabase project:

```bash
npx supabase gen types typescript \
  --project-id oojpipspxwdmiyaymldo \
  --schema public \
  > src/types/supabase.ts
```

Then use them:
```typescript
import type { Database } from '@/types/supabase'

type Profile = Database['public']['Tables']['profiles']['Row']
type InsertMood = Database['public']['Tables']['moods']['Insert']
type UpdatePreferences = Database['public']['Tables']['user_preferences']['Update']
```

---

## 11. SECURITY RULES FOR THE FRONTEND

These rules are ABSOLUTE — violating them creates security vulnerabilities:

1. **Never expose your service role key** in frontend code. Only use `SUPABASE_ANON_KEY`.
2. **Always pass `Authorization: Bearer <token>`** when calling edge functions that require JWT.
3. **Never trust client-supplied `user_id`** — always derive it from `supabase.auth.getUser()`.
4. **Never construct `user_id` from URL params or request bodies** — RLS enforces it server-side.
5. **Always check `error` on every Supabase call** before using `data`.
6. **Profile `is_public = false`** means private — do not attempt to display it or link to it.
7. **Do NOT call `delete_user_account`** — use `delete-user` only.
8. **All user data is scoped by `user_id`** — always filter by the authenticated user's ID.

---

## 12. MANUAL DASHBOARD TASKS (cannot be done via code)

The following must be enabled manually in the Supabase Dashboard:

**Authentication → Password Settings:**
- Enable "Leaked password protection" (HaveIBeenPwned.org check)
  URL: https://supabase.com/dashboard/project/oojpipspxwdmiyaymldo/auth/providers

**Edge Functions:**
- `wandermood_ai` — verify JWT is now enabled (check after the recent fix)
  URL: https://supabase.com/dashboard/project/oojpipspxwdmiyaymldo/functions

---

## 13. QUICK REFERENCE CHEAT SHEET

| What you want to do | Table / Endpoint | Auth needed |
|---|---|---|
| Get own profile | `profiles` SELECT | Yes |
| Update profile | `profiles` UPDATE | Yes |
| See another user's profile | `profiles` SELECT | No (if public) |
| Get/set preferences | `user_preferences` | Yes |
| Log mood | `moods` INSERT | Yes |
| See mood history | `moods` SELECT | Yes |
| Create check-in | `user_check_ins` INSERT | Yes |
| Browse activity catalog | `activities` SELECT | No |
| Rate an activity | `activity_ratings` INSERT | Yes |
| Schedule activity | `scheduled_activities` INSERT | Yes |
| Get upcoming schedule | `scheduled_activities` SELECT | Yes |
| Log visited place | `visited_places` INSERT | Yes |
| Save/unsave a place | `user_saved_places` INSERT/DELETE | Yes |
| AI chat / recommendations | `moody` edge function | Yes (JWT) |
| Load chat history | `ai_conversations` SELECT | Yes |
| Delete chat thread | `ai_conversations` DELETE | Yes |
| Read place recommendations from cache | `places_cache` SELECT | No |
| Write to place cache | `places_cache` INSERT | Yes |
| Get weather | `weather_cache` SELECT | No |
| Get booking links | `gyg_links` SELECT | No |
| Delete account | `delete-user` edge function | Yes (JWT) |
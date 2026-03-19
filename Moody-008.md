# WanderMood — UX Issues Agent Prompt
## Complete Fix Specification: Frontend Logic, State, and Flow

> **How to use this document**: Every issue below is a real UX problem observed in
> the WanderMood app. For each issue, you will find the exact root cause, the screens
> affected, the backend tables/endpoints involved, and the precise code-level fix the
> agent must implement. Fix them in order — many issues are dependent on each other.

---

## ISSUE 1 — MoodyHub → MyDay: Plan destination is invisible to the user

### What is broken
The user selects a mood in MoodyHub and taps "Generate Plan". A plan is produced by
the `moody` edge function, but the user has no idea where this plan goes. There is no
navigation, no toast, no indicator that anything was saved. The user is left on MoodyHub
wondering what happened.

### Root cause
- The response from the `moody` function is rendered in-place on MoodyHub but is
  never persisted to `scheduled_activities` or surfaced to the MyDay screen.
- There is no navigation action after plan generation completes.
- State is not shared between MoodyHub and MyDay.

### Backend tables involved
- `scheduled_activities` — where the generated plan must be saved
- `moods` — the mood log entry should be inserted at the moment of generation
- `user_check_ins` — optional but recommended: log the check-in simultaneously

### Exact fix required

**Step 1 — After the moody function returns a plan, immediately persist it:**
```typescript
// After calling the moody edge function and receiving recommendations:
const activitiesToSchedule = recommendations.map((rec) => ({
  user_id: user.id,
  activity_id: rec.place_id || rec.id,
  name: rec.name,
  description: rec.description,
  image_url: rec.image_url,
  start_time: rec.suggested_start_time,   // moody should return this
  duration: rec.duration_minutes ?? 60,
  location_name: rec.location_name,
  latitude: rec.lat,
  longitude: rec.lng,
  scheduled_date: new Date().toISOString().split('T')[0],  // today
  payment_type: rec.payment_type ?? 'free',
  place_id: rec.place_id,
}))

const { error } = await supabase
  .from('scheduled_activities')
  .insert(activitiesToSchedule)

if (error) {
  toast.error('Could not save your plan. Please try again.')
  return
}
```

**Step 2 — Simultaneously insert a mood log entry:**
```typescript
await supabase.from('moods').insert({
  user_id: user.id,
  mood: selectedMood,
  energy_level: selectedEnergyLevel,
  location: userLocationName,
  created_at: new Date().toISOString(),
})
```

**Step 3 — Navigate to MyDay immediately after save:**
```typescript
// React Navigation / Next.js router — navigate to MyDay, not back to MoodyHub
router.push('/my-day')
// OR in React Native:
navigation.navigate('MyDay', { planDate: today, freshPlan: true })
```

**Step 4 — Show a confirmation before navigating:**
```typescript
// Toast or inline message — appears for 2 seconds, then nav fires
toast.success('Your day plan is ready! ✨')
setTimeout(() => router.push('/my-day'), 1500)
```

---

## ISSUE 2 — Loading Screen: Static, no personality, no feedback

### What is broken
The screen shown while the AI generates a plan is a plain spinner or blank screen.
It does not reflect WanderMood's personality (Moody character, playful tone, mood
energy). For a young target audience, this is a critical engagement gap.

### Root cause
The loading screen is a single static component with no animation, no copy variation,
and no sense of what is happening behind the scenes.

### Exact fix required

**Step 1 — Create a dedicated `MoodyLoadingScreen` component:**
The component must have these elements:
- Moody character animation (Lottie file or CSS keyframe animation — use existing
  brand assets)
- Rotating set of loading messages that change every 1.8 seconds

**Step 2 — Loading messages must be mood-aware. Use this copy map:**
```typescript
const loadingMessages: Record<string, string[]> = {
  happy: [
    "Moody is scanning Rotterdam for good vibes... 🌟",
    "Finding the sunniest spots for your mood...",
    "Almost there — your happy day is loading ✨",
  ],
  adventurous: [
    "Moody is hunting down your next adventure 🗺️",
    "Plotting an epic route through the city...",
    "Hold tight — something wild is coming 🔥",
  ],
  calm: [
    "Finding your perfect quiet corner... 🍃",
    "Moody is curating a peaceful day for you...",
    "Slow and steady — your calm plan is almost ready 🌿",
  ],
  tired: [
    "Moody found the coziest spots for you ☕",
    "Low effort, high reward — loading your easy day...",
    "Almost done — today will be gentle 🛋️",
  ],
  // Add one entry per mood in your mood taxonomy
}

// Usage in component:
const messages = loadingMessages[selectedMood] ?? [
  "Moody is thinking...",
  "Almost there...",
  "Your plan is nearly ready ✨",
]
```

**Step 3 — Animate the message transitions:**
```typescript
// Cycle messages every 1800ms using useEffect + useState
const [messageIndex, setMessageIndex] = useState(0)
useEffect(() => {
  const interval = setInterval(() => {
    setMessageIndex(i => (i + 1) % messages.length)
  }, 1800)
  return () => clearInterval(interval)
}, [messages.length])
```

**Step 4 — Show a subtle progress indicator (NOT a spinner):**
Use a thin animated bar at the top of the screen that moves from 0% to 85% over
4 seconds, then jumps to 100% when the API call completes.

---

## ISSUE 3 — Your Day Plan Screen: No visual hierarchy, too much grey, cards don't pop

### What is broken
The generated day plan is displayed as a flat list of text. Morning / Afternoon / Evening
sections are not visually distinct. Cards use grey backgrounds and grey text, making
everything blend together. There is no visual identity on this screen.

### Root cause
The card component has no visual differentiation between time sections, no images,
and no clear primary/secondary content hierarchy.

### Exact fix required

**Step 1 — Structure the data by time slot before rendering:**
```typescript
// After fetching from scheduled_activities:
const { data: activities } = await supabase
  .from('scheduled_activities')
  .select('*')
  .eq('user_id', user.id)
  .eq('scheduled_date', today)
  .order('start_time', { ascending: true })

const grouped = {
  morning:   activities.filter(a => getHour(a.start_time) < 12),
  afternoon: activities.filter(a => getHour(a.start_time) >= 12 && getHour(a.start_time) < 17),
  evening:   activities.filter(a => getHour(a.start_time) >= 17),
}
```

**Step 2 — Each time section must have a distinct visual header:**
```
Morning   → warm amber gradient header, sun icon
Afternoon → soft coral gradient header, compass icon  
Evening   → deep purple gradient header, moon icon
```

**Step 3 — Activity card must contain these elements in this order:**
```
1. Full-width image (from places_cache or image_url) — 180px tall, rounded top corners
2. Category pill (e.g. "Outdoor · Free") — top-left overlay on the image
3. Activity name — 18px bold, black
4. Location name — 13px grey, with map pin icon
5. Time + duration — 13px, with clock icon
6. "Add to My Day" CTA button — primary brand color, full width
7. "Not for me" link — small, grey, below the CTA
```

**Step 4 — Remove all grey card backgrounds.** Use white cards with a subtle
shadow (`box-shadow: 0 2px 12px rgba(0,0,0,0.08)`) on a light warm-tinted page
background (not `#F5F5F5` — use `#FBF9F6` or your brand warm off-white).

---

## ISSUE 4 — 'Not for me': Mechanical replacement with no AI feedback

### What is broken
Tapping "Not for me" swaps the activity, but the replacement feels random. Moody
gives no acknowledgement that it "understood" the rejection. The interaction feels
like a shuffle button, not an intelligent assistant.

### Root cause
- The replacement call does not pass any rejection context to the `moody` function.
- There is no optimistic UI feedback before the new activity loads.
- The `user_preference_patterns` table is not updated on rejection.

### Exact fix required

**Step 1 — Show immediate AI-voice feedback before the API call:**
```typescript
const notForMeMessages = [
  "Got it! Let me find something better for you 🔄",
  "No worries, Moody has more ideas ✨",
  "Fair enough! Here's another option 👀",
]
toast(randomFrom(notForMeMessages), { duration: 1500 })
```

**Step 2 — Pass rejection context to the replacement call:**
```typescript
const replacement = await fetch(
  'https://oojpipspxwdmiyaymldo.supabase.co/functions/v1/moody',
  {
    method: 'POST',
    headers: { Authorization: `Bearer ${session.access_token}` },
    body: JSON.stringify({
      action: 'replace_activity',
      rejected_activity_id: activity.activity_id,
      rejected_activity_name: activity.name,
      rejected_tags: activity.tags,
      current_mood: currentMood,
      time_slot: activity.time_slot,  // 'morning' | 'afternoon' | 'evening'
      user_id: user.id,
    }),
  }
)
```

**Step 3 — Update `user_preference_patterns` to record the rejection:**
```typescript
// This teaches the system what the user dislikes
// Do this client-side immediately (optimistic), backend confirms
const { data: patterns } = await supabase
  .from('user_preference_patterns')
  .select('tag_counts')
  .eq('user_id', user.id)
  .single()

// Decrement scores for rejected tags (or note them as negative)
// The moody function should handle this server-side when action = 'replace_activity'
```

**Step 4 — Animate the card swap (do NOT do a hard re-render):**
```
Fade out rejected card (200ms) → slide in new card from right (300ms)
Use CSS transitions or React Native Animated API
Never use setState that causes full list re-render
```

---

## ISSUE 5 — Activity Detail Page: 'Add to My Day' does nothing visible

### What is broken
Tapping "Add to My Day" on the activity detail page either does nothing visible,
navigates somewhere unexpected, or shows no confirmation. The user cannot tell if
the action worked.

### Root cause
- The `scheduled_activities` INSERT likely succeeds but there is no UI feedback.
- There is no navigation back to MyDay after adding.
- MyDay screen does not re-fetch when it comes back into focus.

### Exact fix required

**Step 1 — The "Add to My Day" button must follow this exact sequence:**
```typescript
const addToMyDay = async (activity: ActivityDetail) => {
  // 1. Disable button immediately (prevent double-tap)
  setIsAdding(true)

  // 2. Insert into scheduled_activities
  const { error } = await supabase
    .from('scheduled_activities')
    .insert({
      user_id: user.id,
      activity_id: activity.place_id,
      name: activity.name,
      description: activity.description,
      image_url: activity.photo_url,
      start_time: calculateNextAvailableSlot(),  // see Step 3
      duration: activity.estimated_duration ?? 60,
      location_name: activity.formatted_address,
      latitude: activity.lat,
      longitude: activity.lng,
      scheduled_date: selectedDate ?? today,
      payment_type: activity.price_level ? 'paid' : 'free',
      place_id: activity.place_id,
    })

  if (error) {
    toast.error('Could not add to your day. Try again.')
    setIsAdding(false)
    return
  }

  // 3. Show success state on the button (checkmark, green)
  setAddedSuccessfully(true)

  // 4. Show toast confirmation
  toast.success(`${activity.name} added to your day! 🎉`)

  // 5. After 1.5s, navigate back (or close the sheet if it's a bottom sheet)
  setTimeout(() => {
    navigation.goBack()
    // OR: router.push('/my-day')
  }, 1500)
}
```

**Step 2 — Button states (must be visually distinct):**
```
Default:  "Add to My Day"   → brand color background, white text
Loading:  spinner icon       → grey background, disabled
Success:  "✓ Added!"         → green background, white text, 1.5s then auto-dismiss
Error:    "Try again"        → red background, white text
```

**Step 3 — `calculateNextAvailableSlot()` logic:**
```typescript
const calculateNextAvailableSlot = async (): Promise<string> => {
  const { data: existing } = await supabase
    .from('scheduled_activities')
    .select('start_time, duration')
    .eq('user_id', user.id)
    .eq('scheduled_date', today)
    .order('start_time', { ascending: false })
    .limit(1)

  if (!existing || existing.length === 0) {
    // Default: start at 9:00 AM today
    return setTodayHour(9)
  }

  const last = existing[0]
  const lastEnd = addMinutes(last.start_time, last.duration)
  return addMinutes(lastEnd, 15)  // 15 min buffer between activities
}
```

---

## ISSUE 6 — Screen Synchronization: State changes don't propagate across screens

### What is broken
Adding an activity on the Detail page, Explore page, or MoodyHub does not update
MyDay. Rating an activity does not update activity_ratings. The app shows stale data
on every screen because there is no shared state or refetch-on-focus logic.

### Root cause
Each screen fetches data once on mount and never re-fetches. There is no global
state manager and no Supabase realtime subscription keeping screens in sync.

### Exact fix required

**Step 1 — Add refetch-on-focus to every screen that displays scheduled_activities:**
```typescript
// React Native:
useFocusEffect(
  useCallback(() => {
    fetchMyDayActivities()
    fetchUserProfile()
  }, [])
)

// Next.js (when tab/window regains focus):
useEffect(() => {
  const handleFocus = () => fetchMyDayActivities()
  window.addEventListener('focus', handleFocus)
  return () => window.removeEventListener('focus', handleFocus)
}, [])
```

**Step 2 — Implement a Supabase realtime subscription on MyDay:**
```typescript
useEffect(() => {
  const channel = supabase
    .channel('my-day-activities')
    .on('postgres_changes', {
      event: '*',  // INSERT, UPDATE, DELETE
      schema: 'public',
      table: 'scheduled_activities',
      filter: `user_id=eq.${user.id}`,
    }, () => {
      // Re-fetch the full list (don't patch in-place — too error prone)
      fetchMyDayActivities()
    })
    .subscribe()

  return () => supabase.removeChannel(channel)
}, [user.id])
```

**Step 3 — Create a global app state context for the plan:**
```typescript
// AppContext.tsx
interface AppState {
  todayActivities: ScheduledActivity[]
  currentMood: string | null
  refreshTodayActivities: () => Promise<void>
}

// Any screen that modifies scheduled_activities must call:
await appContext.refreshTodayActivities()
// This triggers a re-fetch and all subscribed screens update
```

**Step 4 — Profile stats (`posts_count`, `places_visited_count`, `mood_streak`)
must be updated server-side via triggers — do NOT update them client-side.**
They should auto-reflect correctly because they are derived. Verify triggers exist
in the DB; if not, add them.

---

## ISSUE 7 — 'Add rest to my day' CTA: Purpose is unclear, transition is abrupt

### What is broken
The button exists but users do not understand what it does or what will happen.
After clicking, the transition gives no explanation and the result is not obvious.

### Root cause
- No tooltip, sub-label, or micro-copy explaining the action
- No animation or visual preview of what "rest" means in the plan
- The action (likely inserting a rest block into `scheduled_activities`) has no
  visible result or confirmation

### Exact fix required

**Step 1 — Add micro-copy below the button:**
```
[Add rest to my day]
"Adds a 30-min downtime block between your activities"
```

**Step 2 — Implement the action properly:**
```typescript
const addRestBlock = async () => {
  const nextSlot = await calculateNextAvailableSlot()

  await supabase.from('scheduled_activities').insert({
    user_id: user.id,
    activity_id: 'rest-block',       // special internal ID
    name: '🛋️ Rest & Recharge',
    description: 'A moment to breathe between activities',
    start_time: nextSlot,
    duration: 30,
    payment_type: 'free',
    scheduled_date: today,
    tags: 'rest,wellness,break',
  })

  toast.success('Rest block added to your day 🌿')
  await appContext.refreshTodayActivities()
}
```

**Step 3 — Give rest blocks a distinct visual style in MyDay:**
- Lighter background (pastel green or lavender)
- No image
- Softer typography
- No "Not for me" button on rest blocks

---

## ISSUE 8 — MyDay Screen: Empty state confusion, no status tracking, no completion trigger

### What is broken (3 separate problems):

**8A — Empty state:** When MyDay has no activities (first use or new day), the user
sees a blank or generic screen with no explanation and no call-to-action.

**8B — Status tracking:** There is no way to mark an activity as "started",
"in progress", or "done". The `is_confirmed` column exists but is unused in the UI.

**8C — Completion trigger:** When an activity is done, there is no prompt to
review it, which means `activity_ratings` stays empty and preference learning
never happens.

### Exact fix required

**8A — Empty state design:**
```typescript
// Check if activities list is empty after fetch
if (activities.length === 0) {
  return <MyDayEmptyState
    mood={currentMood}
    onGeneratePlan={() => router.push('/moody-hub')}
    onExplorePlaces={() => router.push('/explore')}
  />
}

// MyDayEmptyState content:
// - Moody character looking curious/expectant
// - Headline: "Your day is wide open ✨"
// - Subtext: "Let Moody plan something for your [mood] mood"
// - Primary CTA: "Plan my day with Moody" → navigates to MoodyHub
// - Secondary CTA: "Browse activities" → navigates to Explore
```

**8B — Activity status tracking:**

Add a `status` field to the UI layer (stored in `scheduled_activities.metadata` as
JSON — do NOT add a new column):
```typescript
// Status values: 'upcoming' | 'active' | 'done' | 'skipped'

// Store status in the metadata JSONB field:
await supabase
  .from('scheduled_activities')
  .update({ metadata: { status: 'done', completed_at: new Date().toISOString() } })
  .eq('id', activityId)
  .eq('user_id', user.id)
```

**Visual status indicators on cards:**
```
upcoming → white card, normal text
active   → brand color left border (4px), subtle pulsing dot indicator
done     → grey out, strikethrough on activity name, ✓ checkmark badge
skipped  → grey dashed border, italic text
```

**Step to mark active:** Auto-mark as "active" when current time is within 15
minutes of `start_time`. Do this in a `useEffect` that runs every 60 seconds:
```typescript
useEffect(() => {
  const interval = setInterval(() => {
    const now = new Date()
    activities.forEach(async (a) => {
      const startTime = new Date(a.start_time)
      const diffMins = (startTime.getTime() - now.getTime()) / 60000
      if (diffMins <= 15 && diffMins > -60) {
        // Mark as active if not already
        if (getStatus(a) !== 'active') {
          await updateActivityStatus(a.id, 'active')
        }
      }
    })
  }, 60000)
  return () => clearInterval(interval)
}, [activities])
```

**8C — Completion → Review trigger:**

When user marks activity as "done" (tap checkmark), immediately show review prompt:
```typescript
const markAsDone = async (activity: ScheduledActivity) => {
  await updateActivityStatus(activity.id, 'done')

  // Show review bottom sheet after 800ms (let the done animation play first)
  setTimeout(() => {
    openReviewSheet({
      activityId: activity.activity_id,
      activityName: activity.name,
      placeName: activity.location_name,
      currentMood: currentMood,
    })
  }, 800)
}

// ReviewSheet submits to:
await supabase.from('activity_ratings').insert({
  user_id: user.id,
  activity_id: activity.activityId,
  activity_name: activity.activityName,
  place_name: activity.placeName,
  stars: rating,           // 1-5 from star picker
  mood: activity.currentMood,
  would_recommend: wouldRecommend,
  notes: reviewText,
  completed_at: new Date().toISOString(),
})
```

---

## ISSUE 9 — Explore Screen: Not connected to MyDay, no save-for-later flow

### What is broken
Explore shows activities and places, but the "Add to My Day" path is broken or
inconsistent. There is no way to save something for a future date. Saved places
(`user_saved_places`) exist in the DB but are not surfaced.

### Exact fix required

**Step 1 — Every place card in Explore must have two action buttons:**
```
[Add to today]     → inserts into scheduled_activities for today's date
[Save for later]   → inserts into user_saved_places
```

**Step 2 — "Add to today" uses the same flow as Issue 5:**
```typescript
// Reuse the exact same addToMyDay() function from Issue 5
// This ensures consistency
```

**Step 3 — "Save for later" flow:**
```typescript
const saveForLater = async (place: PlaceResult) => {
  // Check if already saved (prevent duplicates)
  const { data: existing } = await supabase
    .from('user_saved_places')
    .select('id')
    .eq('user_id', user.id)
    .eq('place_id', place.place_id)
    .single()

  if (existing) {
    toast('Already in your saved places 📌')
    return
  }

  await supabase.from('user_saved_places').insert({
    user_id: user.id,
    place_id: place.place_id,
    place_name: place.name,
    place_data: place,  // snapshot the full object
  })

  toast.success('Saved! Find it in your profile 📌')
  // Toggle heart/bookmark icon to filled state
  setSaved(true)
}
```

**Step 4 — Explore must read from `places_cache` first:**
```typescript
// Before calling Google Places API, always check the cache:
const cacheKey = `explore:${lat}:${lng}:${mood}:${category}`

const { data: cached } = await supabase
  .from('places_cache')
  .select('data')
  .eq('cache_key', cacheKey)
  .gt('expires_at', new Date().toISOString())
  .single()

if (cached) {
  setPlaces(cached.data.results)
  return
}

// Cache miss: call Google Places, then write result back:
const apiResult = await fetchFromGooglePlaces(...)
await supabase.from('places_cache').upsert({
  cache_key: cacheKey,
  data: apiResult,
  request_type: 'explore',
  expires_at: addHours(new Date(), 24).toISOString(),
  user_id: user.id,
}, { onConflict: 'cache_key' })
```

---

## ISSUE 10 — Future Planning: App only works for today

### What is broken
Every flow assumes "today". There is no date picker for planning tomorrow or a
future trip. `scheduled_activities.scheduled_date` supports future dates — it just
isn't exposed in the UI.

### Exact fix required

**Step 1 — Add a date selector to MyDay screen (top of screen, horizontal scroll):**
```typescript
// Show 7 days: yesterday (read-only), today (default), next 5 days
const dates = [-1, 0, 1, 2, 3, 4, 5].map(offset => addDays(today, offset))

// Render as horizontal pill selector:
// [Thu 19] [Fri 20 ★] [Sat 21] [Sun 22] [Mon 23] ...
// ★ = today
```

**Step 2 — When user selects a date, re-fetch scheduled_activities for that date:**
```typescript
const [selectedDate, setSelectedDate] = useState(today)

const fetchActivitiesForDate = async (date: string) => {
  const { data } = await supabase
    .from('scheduled_activities')
    .select('*')
    .eq('user_id', user.id)
    .eq('scheduled_date', date)
    .order('start_time', { ascending: true })

  setActivities(data ?? [])
}

useEffect(() => {
  fetchActivitiesForDate(selectedDate)
}, [selectedDate])
```

**Step 3 — Pass `selectedDate` to all "Add to My Day" and "Generate Plan" flows:**
```typescript
// MoodyHub: ask user "Plan for which day?"
// Default = today, but allow selection of next 7 days
// Pass selected date to moody function + to scheduled_activities INSERT
```

---

## ISSUE 11 — Profile Screen: Fails to load, lacks purpose

### What is broken
The profile screen often shows a loading state that never resolves, or displays
empty data. Even when it loads, the screen has no clear purpose — it doesn't tell
the user anything meaningful about themselves.

### Root cause
- Profile fetch has no error handling, so it silently fails and spins
- `is_public` logic is missing (the view policy was broken — now fixed in DB)
- No meaningful data is displayed even when profile loads correctly

### Exact fix required

**Step 1 — Robust profile fetch with error handling:**
```typescript
const fetchProfile = async () => {
  setLoading(true)
  const { data, error } = await supabase
    .from('profiles')
    .select(`
      *,
      user_preferences (
        has_completed_onboarding,
        budget_level,
        travel_style,
        selected_moods
      )
    `)
    .eq('id', user.id)
    .single()

  if (error) {
    if (error.code === 'PGRST116') {
      // Profile doesn't exist yet — create it
      await createDefaultProfile(user)
    } else {
      setError('Could not load your profile. Pull to refresh.')
    }
  } else {
    setProfile(data)
  }

  setLoading(false)
}
```

**Step 2 — Profile screen must display these sections in order:**
```
1. Avatar (image_url) + name + username + bio
2. Stats row: [X places visited] [X mood streak 🔥] [X days active]
   → pull from profiles.places_visited_count, profiles.mood_streak
3. "Your mood profile" — chips showing profiles.travel_vibes + profiles.interests
4. "Saved places" — horizontal scroll of user_saved_places (max 5, "See all" link)
5. "Recent activity" — last 3 entries from activity_ratings
6. Settings row: Edit Profile | Preferences | Notifications | Delete Account
```

**Step 3 — "Saved places" section:**
```typescript
const { data: savedPlaces } = await supabase
  .from('user_saved_places')
  .select('place_id, place_name, place_data')
  .eq('user_id', user.id)
  .order('saved_at', { ascending: false })
  .limit(5)
```

---

## ISSUE 12 — Splash Screen: Generic, no personality

### What is broken
The splash screen shows the logo and a tagline, then loads the app. It creates no
emotional connection, no sense of what the app does, and no excitement.

### Exact fix required

**Step 1 — The splash screen must do these things in sequence:**

```
0ms    → Moody character appears (bounce-in animation, 400ms)
400ms  → Logo fades in below Moody (fade, 300ms)
700ms  → Tagline types in letter-by-letter: "Your mood. Your day." (600ms)
1300ms → While animation plays, check auth state in background:
           - if logged in + onboarding done → navigate to MyDay
           - if logged in + onboarding not done → navigate to Onboarding
           - if not logged in → navigate to Welcome/Login screen
1500ms → Start fade-out of splash (if auth check is done)
```

**Step 2 — Auth check during splash (non-blocking):**
```typescript
useEffect(() => {
  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
      // Not logged in — will navigate after animation
      setDestination('/welcome')
      return
    }

    const { data: prefs } = await supabase
      .from('user_preferences')
      .select('has_completed_onboarding')
      .eq('user_id', session.user.id)
      .single()

    setDestination(
      prefs?.has_completed_onboarding ? '/my-day' : '/onboarding'
    )
  }

  checkAuth()
}, [])

// Navigate after animation completes (min 1500ms, max 3000ms)
useEffect(() => {
  if (!destination) return
  const timer = setTimeout(() => router.replace(destination), Math.max(1500, animationDone ? 0 : 3000))
  return () => clearTimeout(timer)
}, [destination, animationDone])
```

---

## GLOBAL ISSUE — Fragmented user journey: Actions don't connect across screens

### What is broken
Every issue above is a symptom of one root cause: there is no shared app state and
no consistent pattern for how data flows between screens.

### The architecture fix (implement this first, before touching UI)

**Create a single `AppProvider` context that wraps the entire app:**

```typescript
// providers/AppProvider.tsx

interface AppContextValue {
  // Auth
  user: User | null
  session: Session | null

  // Today's plan
  selectedDate: string            // 'YYYY-MM-DD'
  setSelectedDate: (d: string) => void
  todayActivities: ScheduledActivity[]
  isLoadingActivities: boolean
  refreshActivities: () => Promise<void>

  // User state
  profile: Profile | null
  preferences: UserPreferences | null
  currentMood: string | null
  setCurrentMood: (mood: string) => void

  // Preference patterns (for AI personalization)
  patterns: UserPreferencePatterns | null
}

export const AppProvider = ({ children }) => {
  // Single source of truth for the whole app
  // All screens read from here, all mutations call refreshActivities() after
}
```

**Every screen that needs activities:**
```typescript
const { todayActivities, refreshActivities } = useApp()
// Does NOT fetch independently — reads from shared context
// After any mutation (insert/update/delete), calls refreshActivities()
```

**Navigation state: always pass `freshPlan` flag when returning to MyDay
from a plan-generating flow:**
```typescript
// When landing on MyDay with freshPlan=true, show a brief "Here's your plan 🎉" header
navigation.navigate('MyDay', { freshPlan: true })
```

---

## SUMMARY CHECKLIST FOR THE AGENT

Fix these in order. Each item is a prerequisite for the next.

```
[ ] 1.  Create AppProvider context — shared state for all screens
[ ] 2.  Fix splash screen auth routing logic
[ ] 3.  Add refetch-on-focus to MyDay, Explore, Profile screens
[ ] 4.  Add Supabase realtime subscription to MyDay
[ ] 5.  Fix "Add to My Day" button: INSERT + feedback + navigate (Issues 5, 9)
[ ] 6.  Fix MoodyHub: persist plan to scheduled_activities on generation (Issue 1)
[ ] 7.  Build MoodyLoadingScreen with mood-aware copy (Issue 2)
[ ] 8.  Rebuild DayPlan cards: images, hierarchy, time sections (Issue 3)
[ ] 9.  Fix "Not for me": pass rejection context to moody function (Issue 4)
[ ] 10. Add activity status tracking: upcoming/active/done/skipped (Issue 8B)
[ ] 11. Add completion → review trigger flow (Issue 8C)
[ ] 12. Fix MyDay empty state (Issue 8A)
[ ] 13. Add date selector to MyDay for future planning (Issue 10)
[ ] 14. Fix "Add rest to my day" CTA with proper insert + micro-copy (Issue 7)
[ ] 15. Connect Explore to places_cache, add save-for-later (Issue 9)
[ ] 16. Fix profile screen: robust fetch + meaningful content sections (Issue 11)
```

---

## SUPABASE TABLES USED IN EACH ISSUE

| Issue | Tables / Endpoints |
|---|---|
| 1 — MoodyHub → MyDay | `scheduled_activities`, `moods`, `user_check_ins` |
| 2 — Loading screen | `moody` edge function |
| 3 — Day plan cards | `scheduled_activities`, `places_cache` |
| 4 — Not for me | `moody` edge function, `user_preference_patterns` |
| 5 — Add to My Day | `scheduled_activities` |
| 6 — Screen sync | `scheduled_activities` (realtime), `profiles` |
| 7 — Add rest | `scheduled_activities` |
| 8 — MyDay | `scheduled_activities`, `activity_ratings`, `user_check_ins` |
| 9 — Explore | `places_cache`, `user_saved_places`, `scheduled_activities` |
| 10 — Future planning | `scheduled_activities` (scheduled_date column) |
| 11 — Profile | `profiles`, `user_preferences`, `user_saved_places`, `activity_ratings` |
| 12 — Splash | `auth.users`, `user_preferences` |
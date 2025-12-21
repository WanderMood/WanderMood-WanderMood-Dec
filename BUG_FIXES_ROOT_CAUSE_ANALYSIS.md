# Bug Fixes - Root Cause Analysis & Implementation Plan

## Execution Order

### Phase 1: Critical Navigation & Auth (Bugs A, C, G)
### Phase 2: Profile & Settings (Bugs B, F)  
### Phase 3: Data & Features (Bugs D, E, H)

---

## BUG A: Remember Me Not Working

### Root Cause
- `_rememberMe` checkbox state is stored in widget state but never persisted
- Supabase automatically persists sessions, but we're not checking for existing sessions on app startup
- The checkbox value is never used in login logic

### Affected Files
- `lib/features/auth/presentation/screens/login_screen.dart` (lines 29, 307-314, 66-99)
- `lib/features/splash/presentation/screens/splash_screen.dart` (lines 143-226)
- `lib/core/router/router.dart` (redirect logic)

### Fix Strategy
1. Load `_rememberMe` state from SharedPreferences on init
2. Save `_rememberMe` state to SharedPreferences when toggled
3. On login, if `_rememberMe` is false, explicitly sign out on app close (optional)
4. On app startup, check for existing Supabase session and restore if present
5. Update splash screen to properly handle session restoration

### Expected Behavior
- ✅ When enabled: User stays logged in after app restart
- ✅ When disabled: User must log in again (session cleared on logout)
- ✅ Works for email/password and OAuth logins

---

## BUG C: Onboarding Skip Causes Infinite Loop

### Root Cause
- Skip button navigates to `/auth/signup` but doesn't set `has_seen_onboarding` flag
- Router checks `has_seen_onboarding` and redirects back to onboarding
- Creates infinite redirect loop

### Affected Files
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` (line 107)
- `lib/core/router/router.dart` (redirect logic)
- `lib/features/splash/presentation/screens/splash_screen.dart` (line 213)

### Fix Strategy
1. When Skip is clicked, set `has_seen_onboarding = true` in SharedPreferences
2. Then navigate to `/auth/signup`
3. Ensure router respects this flag and doesn't redirect back

### Expected Behavior
- ✅ Skip sets `has_seen_onboarding=true` persistently
- ✅ Onboarding shown ONLY when `has_seen_onboarding=false`
- ✅ After signup/login, user never sees onboarding again

---

## BUG G: Hamburger Menu Not Working

### Root Cause
- `MainScreen` doesn't have a `Scaffold` with `drawer` property
- Profile navigation uses `context.push('/profile')` instead of drawer
- No hamburger menu icon/button visible

### Affected Files
- `lib/features/home/presentation/screens/main_screen.dart` (no drawer implementation)
- `lib/features/profile/presentation/widgets/profile_drawer.dart` (exists but not used)

### Fix Strategy
1. Add `Scaffold` with `drawer` property to `MainScreen`
2. Use `ProfileDrawer` widget as drawer content
3. Add hamburger menu icon in AppBar or as floating button
4. Ensure drawer actions navigate correctly

### Expected Behavior
- ✅ Hamburger menu opens reliably
- ✅ Menu items navigate correctly
- ✅ Menu reflects real user state (logged in/out)

---

## BUG B: Profile Data Broken (Name + Profile Picture)

### Root Cause
- Name from signup is stored in `userMetadata` but not saved to `profiles` table
- Profile picture upload may fail due to missing storage bucket or RLS policies
- Profile screen may be reading from wrong source

### Affected Files
- `lib/features/auth/presentation/screens/register_screen.dart` (line 81 - name in metadata)
- `lib/features/auth/application/auth_service.dart` (profile creation)
- `lib/features/profile/presentation/screens/profile_screen.dart` (profile loading)
- `lib/features/profile/presentation/screens/profile_edit_screen.dart` (profile update)

### Fix Strategy
1. Ensure `_createUserProfile` is called after signup with correct name
2. Verify Supabase Storage bucket exists and RLS policies are correct
3. Ensure profile screen reads from `profiles` table, not userMetadata
4. Fix profile picture upload to use correct bucket path

### Expected Behavior
- ✅ Name entered at signup saved to backend and shown on Profile screen
- ✅ User can update name and profile picture
- ✅ Changes persist and update UI immediately
- ✅ Profile photo stored in Supabase Storage (correct bucket + RLS)

---

## BUG F: Profile Settings Not Working (Language, Preferences)

### Root Cause
- Language change may not be wired to localization system
- Settings not persisted to backend or local storage
- Profile screen actions may not be connected to update logic

### Affected Files
- `lib/features/profile/presentation/screens/language_screen.dart`
- `lib/features/profile/presentation/screens/settings_screen.dart`
- `lib/features/profile/domain/providers/profile_provider.dart`

### Fix Strategy
1. Wire language change to app localization
2. Persist settings to `user_preferences` table in Supabase
3. Ensure settings are loaded on app startup
4. Update UI immediately when settings change

### Expected Behavior
- ✅ Language change updates app locale immediately
- ✅ Settings persist across app restarts
- ✅ Profile screen fully functional

---

## BUG E: Explore Screen Shows "No Places Found"

### Root Cause
- May be using mock data or broken queries
- API keys may not be available in release builds
- Location permissions may not be handled correctly

### Affected Files
- `lib/features/home/presentation/screens/explore_screen.dart`
- `lib/features/places/providers/explore_places_provider.dart`
- `lib/features/places/services/places_service.dart`

### Fix Strategy
1. Remove all mock data from Explore screen
2. Ensure Places API key is available via `--dart-define` in release builds
3. Fix data source, queries, and filters
4. Add proper fallback location if permissions denied

### Expected Behavior
- ✅ Explore loads real places from backend or external APIs
- ✅ Uses fallback location if permissions are denied
- ✅ Shows meaningful empty states only when truly empty

---

## BUG D: Day Plan Generation Fails

### Root Cause
- May be using mock day-plan logic
- API keys may not be injected correctly in release builds
- Error handling may be masking real issues

### Affected Files
- `lib/features/plans/presentation/screens/plan_generation_screen.dart`
- `lib/features/plans/domain/notifiers/plan_generation_notifier.dart`
- `lib/core/services/wandermood_ai_service.dart`

### Fix Strategy
1. Replace mock day-plan logic with real API integration
2. Ensure correct API key injection in release builds
3. Improve error handling and logging
4. Show accurate error messages (API key missing, rate limit, server error)

### Expected Behavior
- ✅ App successfully generates day plan using real backend/API data
- ✅ If failure occurs, show accurate error (API key missing, rate limit, server error)

---

## BUG H: App Still Uses Mock Data

### Root Cause
- Multiple files contain mock/placeholder data
- Mock data may not be gated behind debug-only flags
- Release builds may still use mock data

### Affected Files
- 67 files found with "mock|Mock|MOCK|fake|Fake|FAKE|placeholder|Placeholder"
- Key files:
  - `lib/features/places/presentation/widgets/place_card.dart`
  - `lib/features/mood/presentation/screens/moody_hub_screen.dart`
  - `lib/features/home/presentation/screens/explore_screen.dart`

### Fix Strategy
1. Identify all mock data sources
2. Replace with real repositories/services
3. Gate mock data behind `kDebugMode` flags
4. Ensure release builds never use mock data

### Expected Behavior
- ✅ App uses ONLY real backend data (Supabase + APIs)
- ✅ Mock data fully removed or gated behind debug-only flags

---

## Backend Requirements

### Supabase Tables
- ✅ `profiles` - User profile data
- ✅ `user_preferences` - User settings and preferences
- ✅ `scheduled_activities` - User's scheduled activities
- ✅ `user_check_ins` - Mood check-ins
- ✅ `cached_places` - Places cache
- ✅ `user_saved_places` - Saved places

### Supabase Storage
- ✅ `avatars` bucket - Profile pictures
- ✅ RLS policies for public read, user write

### RLS Policies
- ✅ Users can read/write own profiles
- ✅ Users can read/write own preferences
- ✅ Users can read/write own saved places

### API Keys Required
- ✅ `GOOGLE_PLACES_API_KEY` - For Places API
- ✅ `OPENAI_API_KEY` - For AI features
- ✅ `OPENWEATHER_API_KEY` - For weather
- ✅ `SUPABASE_URL` and `SUPABASE_ANON_KEY` - For backend


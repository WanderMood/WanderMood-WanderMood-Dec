# Complete Authentication Flow: Signup → Moody Hub

## Step-by-Step Flow with Code References

### STEP 1: User Signs Up
**File**: `lib/features/auth/presentation/screens/register_screen.dart` (lines 78-138)

```dart
// User fills form → clicks "Sign Up"
final response = await Supabase.instance.client.auth.signUp(
  email: email,
  password: password,
  data: {'name': name},
  emailRedirectTo: 'io.supabase.wandermood://auth-callback',
);
```

**What happens:**
- Supabase creates user account
- If email confirmations enabled: User receives email, NO session created yet
- If email confirmations disabled: User immediately logged in, session created

**Session state**: 
- If email required: `response.session == null` (user signed out)
- If auto-confirm: `response.session != null` (user logged in)

---

### STEP 2: Email Verification
**File**: `lib/features/auth/presentation/screens/email_verification_screen.dart` (lines 85-143)

**User clicks email link** → Deep link opens app → `/auth-callback`

**File**: `lib/core/router/router.dart` (lines 242-303)
- Route `/auth-callback` calls `_handleEmailVerification()`
- This should refresh session and navigate to preferences

**OR** User manually verifies in app:
```dart
// email_verification_screen.dart line 94
await Supabase.instance.client.auth.refreshSession();
```

**Critical checks:**
- Line 110: `final user = Supabase.instance.client.auth.currentUser;`
- Line 115: `if (user.emailConfirmedAt == null)` → throws error
- Line 123: Sets `hasCompletedPreferences = false`
- Line 130: Navigates to `/preferences/communication`

**Session state**: Should be established after `refreshSession()`

---

### STEP 3: Preferences Onboarding
**File**: `lib/features/onboarding/presentation/screens/communication_preference_screen.dart`
- User fills preferences
- Saves to `user_preferences` table
- Navigates to next screen → eventually to `onboarding_loading_screen.dart`

**File**: `lib/features/onboarding/presentation/screens/onboarding_loading_screen.dart` (lines 540-562)

**After preferences complete:**
```dart
// Line 544
await prefs.setBool('hasCompletedPreferences', true);

// Line 561
context.goNamed('main', extra: {'tab': tabIndex}); // tab 2 for first-time users
```

**Session state**: Should still be valid (from email verification)

---

### STEP 4: MainScreen Loads
**File**: `lib/features/home/presentation/screens/main_screen.dart` (lines 48-94)

**In `initState()`:**
```dart
// Line 64
_prefetchPlacesInBackground(); // ⚠️ THIS IS WHERE AUTH FAILS
```

**The prefetch function (lines 79-94):**
```dart
void _prefetchPlacesInBackground() {
  // Non-blocking - don't await
  ref.read(moodyExploreAutoProvider.future).then((places) {
    // Success
  }).catchError((e) {
    // Error - but non-blocking
  });
}
```

**Session state**: Should be valid, but might not be refreshed

---

### STEP 5: Background Prefetch Calls Edge Function
**File**: `lib/features/places/providers/moody_explore_provider.dart` (lines 86-127)

**Provider calls:**
```dart
// Line 126
return ref.watch(moodyExploreProvider(params).future);
```

**Which calls:**
**File**: `lib/core/services/moody_edge_function_service.dart` (lines 17-58)

```dart
// Line 26
await AuthHelper.ensureValidSession(); // ⚠️ CHECKS SESSION

// Line 46
final response = await _supabase.functions.invoke(
  'moody',
  body: { ... },
);
```

**Critical**: `_supabase.functions.invoke()` should automatically send auth token in headers

---

### STEP 6: Edge Function Receives Request
**File**: `supabase/functions/moody/index.ts` (lines 86-163)

```typescript
// Line 99
const authHeader = req.headers.get('Authorization')

// Line 105
if (!authHeader || !authHeader.startsWith('Bearer ')) {
  return 401 error // ⚠️ THIS IS WHERE IT FAILS
}

// Line 121-125
const supabaseWithAuth = createClient(supabaseUrl, supabaseAnonKey, {
  global: {
    headers: { Authorization: authHeader },
  },
})

// Line 127
const { data: { user: authUser }, error: authError } = await supabaseWithAuth.auth.getUser()

// Line 129
if (authError || !authUser) {
  return 401 error // ⚠️ OR HERE
}
```

---

## 🔴 THE PROBLEM

**"Auth session missing!" error means:**
- Edge Function line 99: `req.headers.get('Authorization')` returns `null`
- OR Edge Function line 127: `getUser()` fails (token invalid/expired)

**Why this happens:**
1. **Session not established**: After email verification, session might not be fully synced
2. **Token not sent**: `functions.invoke()` might not be sending token automatically
3. **Token expired**: Session expired between verification and prefetch

---

## 🔍 WHERE TO CHECK

### Check 1: Is session established after email verification?
**Add logging in**: `email_verification_screen.dart` line 94
```dart
await Supabase.instance.client.auth.refreshSession();
final session = Supabase.instance.client.auth.currentSession;
final token = session?.accessToken;
debugPrint('🔑 Session token after refresh: ${token?.substring(0, 20)}...');
```

### Check 2: Is token sent to Edge Function?
**Supabase Flutter should auto-send**, but verify:
- Check Edge Function logs for `Authorization` header
- If missing, token isn't being sent

### Check 3: Is session valid when prefetch runs?
**Add logging in**: `main_screen.dart` line 79
```dart
void _prefetchPlacesInBackground() {
  final session = Supabase.instance.client.auth.currentSession;
  final user = Supabase.instance.client.auth.currentUser;
  debugPrint('🔑 Prefetch: Session exists: ${session != null}, User: ${user?.id}');
  // ... rest of function
}
```

---

## 🎯 EXPECTED FLOW

1. **Signup** → User created, email sent
2. **Email verification** → `refreshSession()` → Session established → Token in memory
3. **Preferences** → User completes → Navigate to MainScreen
4. **MainScreen loads** → Background prefetch starts
5. **Prefetch calls Edge Function** → `functions.invoke()` auto-sends token
6. **Edge Function receives** → `Authorization: Bearer <token>` header
7. **Edge Function validates** → `getUser()` succeeds → Returns places
8. **Moody Hub shows** → User sees intro overlay

---

## ❌ CURRENT FAILURE POINT

**Most likely**: Step 5-6
- Prefetch runs too early (session not fully synced)
- OR `functions.invoke()` not sending token automatically
- OR Session expired between steps

**Solution**: Added diagnostic logging to identify exact failure point

---

## 🔍 DIAGNOSTIC LOGGING ADDED

### In MainScreen (prefetch check):
**File**: `lib/features/home/presentation/screens/main_screen.dart` (lines 79-94)

Now logs:
- User exists: true/false
- Session exists: true/false  
- Token exists: true/false
- Token preview (first 20 chars)

### In Edge Function Service (before call):
**File**: `lib/core/services/moody_edge_function_service.dart` (lines 38-58)

Now logs:
- Auth token exists: true/false
- Token preview (first 20 chars)
- Warning if no token

### What to look for in logs:

**If you see**: `⚠️ WARNING: No auth token - Edge Function will reject!`
→ Session not established when prefetch runs

**If you see**: Token exists in Flutter but Edge Function says "Auth session missing!"
→ Token not being sent in HTTP headers (Supabase Flutter bug)

**If you see**: Token exists, Edge Function receives it, but `getUser()` fails
→ Token expired or invalid

---

## 📋 TESTING CHECKLIST

1. **Sign up** → Check logs for session creation
2. **Verify email** → Check logs for `refreshSession()` success
3. **Complete preferences** → Check logs for session still valid
4. **MainScreen loads** → Check logs for token existence
5. **Prefetch starts** → Check logs for token being sent
6. **Edge Function receives** → Check Edge Function logs for `Authorization` header

**Expected logs:**
```
🔑 Prefetch Auth Check:
   User exists: true
   Session exists: true
   Token exists: true
   Token preview: eyJhbGciOiJIUzI1NiIs...
🎯 Calling moody Edge Function: get_explore
   🔑 Auth token exists: true
   🔑 Token preview: eyJhbGciOiJIUzI1NiIs...
```

**If token is missing at prefetch**, the session wasn't established properly after email verification.


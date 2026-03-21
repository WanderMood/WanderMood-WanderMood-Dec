# WanderMood — App Store Readiness Fixes
## Cursor Prompt for Giri

---

## AGENT RULES

1. Do NOT touch archived screens or files
2. Do NOT delete any files, tables, or columns
3. Read Moody-007.md and Moody-008.md before touching any UI file
4. One fix at a time — show result, wait for approval, then continue
5. Minimal footprint — smallest possible change that fixes the issue

---

## OVERVIEW

These fixes are required before submitting WanderMood to the Apple App Store
and Google Play Store. None of them require UI redesign — they are bug fixes,
legal requirements, and permission declarations.

---

## FIX 1 — Hide RangeError debug text in MyDay header
**Priority: CRITICAL — causes immediate rejection on both stores**

Find where the `RangeError(end): Invalid value` text is rendered in the MyDay
header (top-left corner). It is currently visible to users in production.

Wrap the offending code in a try/catch and fail silently:

```dart
// BEFORE — crashing or showing debug text
Widget buildHeader() {
  final value = someList[index]; // throws RangeError
  ...
}

// AFTER — catch and hide gracefully
Widget buildHeader() {
  try {
    final value = someList[index];
    ...
  } catch (e) {
    debugPrint('MyDay header error: $e'); // log only in debug
    return const SizedBox.shrink(); // show nothing in production
  }
}
```

Search for `RangeError` in the codebase to find the source. If it's in a
provider/notifier, wrap the state access in a null/bounds check:

```dart
// Safe list access pattern
final item = index < list.length ? list[index] : null;
if (item == null) return const SizedBox.shrink();
```

**Acceptance criteria:** Open MyDay screen — no red/yellow debug text visible
anywhere in the header or on screen.

---

## FIX 2 — Fix "BOTTOM OVERFLOWED BY 14 PIXELS" in Quick Actions cards
**Priority: HIGH — broken layout causes rejection**

Find the Quick Actions section in MyDay screen (the two cards: "Vraag Moody"
and "Activiteit toevoegen"). The cards are overflowing by 14 pixels.

Fix by either:
- Increasing the card height by at least 20px (add padding)
- Or wrapping content in a `FittedBox` or reducing font size slightly

```dart
// Option A — increase card height
Container(
  height: 88, // was probably 74 or similar — increase until overflow stops
  ...
)

// Option B — add more vertical padding inside
Padding(
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
  child: ...
)
```

Test on iPhone SE (small screen) — if it overflows there, increase further.

**Acceptance criteria:** No yellow overflow warning visible on any screen size.

---

## FIX 3 — Add "Delete Account" to Settings screen
**Priority: CRITICAL — Apple will reject without this**

Apple requires account deletion to be findable within 60 seconds by a reviewer.

Find the Settings or Profile screen where "Log Out" is currently shown.
Add a "Delete Account" option below "Log Out".

The `delete-user` edge function already exists in Supabase and handles all
data deletion. Wire the button to it.

```dart
// Add this to Settings screen — below Log Out
ListTile(
  leading: const Icon(Icons.delete_forever_outlined,
    color: Color(0xFFE05C5C)), // wmError red
  title: const Text(
    'Account verwijderen',
    style: TextStyle(
      color: Color(0xFFE05C5C),
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
  ),
  onTap: () => _showDeleteAccountDialog(context),
),

// Confirmation dialog — two taps required (Apple requirement)
Future<void> _showDeleteAccountDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Account verwijderen?'),
      content: const Text(
        'Dit verwijdert je account en alle bijbehorende gegevens '
        'permanent. Dit kan niet ongedaan worden gemaakt.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuleren'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE05C5C),
          ),
          child: const Text('Verwijderen'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await _deleteAccount(context);
  }
}

// Call the existing delete-user edge function
Future<void> _deleteAccount(BuildContext context) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Call the delete-user edge function
    await Supabase.instance.client.functions.invoke('delete-user');

    // Sign out and navigate to login
    await Supabase.instance.client.auth.signOut();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', (route) => false,
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Er is iets misgegaan. Probeer opnieuw.')),
      );
    }
  }
}
```

**Acceptance criteria:** Settings screen shows "Account verwijderen" in red.
Tapping it shows a confirmation dialog. Confirming calls the edge function,
signs the user out, and navigates to the login screen.

---

## FIX 4 — Add Privacy Policy link to Help & Support screen
**Priority: CRITICAL — Apple requires it accessible inside the app**

Find the Help & Support screen. Add a "Privacybeleid" row that opens the
privacy policy URL in the device browser.

```dart
// Add url_launcher to pubspec.yaml if not already there:
// url_launcher: ^6.2.0

import 'package:url_launcher/url_launcher.dart';

// Add this row to Help & Support screen
ListTile(
  leading: const Icon(Icons.privacy_tip_outlined,
    color: Color(0xFF2A6049)), // wmForest
  title: const Text('Privacybeleid'),
  trailing: const Icon(Icons.chevron_right,
    color: Color(0xFF8C8780)), // wmStone
  onTap: () async {
    final url = Uri.parse('https://wandermood.com/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),

// Also add Terms of Service row below it
ListTile(
  leading: const Icon(Icons.description_outlined,
    color: Color(0xFF2A6049)),
  title: const Text('Gebruiksvoorwaarden'),
  trailing: const Icon(Icons.chevron_right,
    color: Color(0xFF8C8780)),
  onTap: () async {
    final url = Uri.parse('https://wandermood.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),
```

**Acceptance criteria:** Help & Support screen shows "Privacybeleid" row.
Tapping it opens `wandermood.com/privacy` in the browser.

---

## FIX 5 — Update Info.plist permission descriptions (iOS)
**Priority: HIGH — vague descriptions cause rejection**

Find `ios/Runner/Info.plist`. Update or add these permission strings with
clear, human-readable descriptions:

```xml
<!-- Location — when in use -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>WanderMood uses your location to find activities, restaurants, and places near you, and to show accurate weather for your area.</string>

<!-- Location — always (only if you use background location, otherwise remove) -->
<!-- Remove this key entirely if you don't use background location -->

<!-- Camera — for profile photo -->
<key>NSCameraUsageDescription</key>
<string>WanderMood uses your camera so you can set a profile photo.</string>

<!-- Photo library — for profile photo -->
<key>NSPhotoLibraryUsageDescription</key>
<string>WanderMood accesses your photo library so you can choose a profile photo.</string>

<!-- Notifications -->
<key>NSUserNotificationsUsageDescription</key>
<string>WanderMood sends reminders about your planned activities and helpful updates about your day.</string>
```

**IMPORTANT:** Remove any permission keys that WanderMood does NOT actually use.
Apple flags unused permissions. If you don't use microphone, Bluetooth, contacts
etc. — remove those keys entirely.

**Acceptance criteria:** Every permission in Info.plist has a clear sentence
explaining exactly why the app needs it. No permissions declared that the app
never uses.

---

## FIX 6 — Add Rotterdam fallback to onboarding
**Priority: MEDIUM — prevents reviewer getting stuck on first launch**

Apple reviewers test apps on a fresh device. If onboarding requires a real
GPS location to proceed, the reviewer may get stuck.

Find where the app first requests location or where the city is set during
onboarding. Add Rotterdam as a hardcoded fallback:

```dart
// In location provider or onboarding — add fallback
Future<String> getUserCity() async {
  try {
    final location = await getCurrentLocation();
    return await reverseGeocode(location) ?? 'Rotterdam';
  } catch (e) {
    return 'Rotterdam'; // Always fall back to Rotterdam
  }
}

// In userLocationProvider — if already exists, just add the fallback
// Rotterdam coordinates: lat 51.9225, lng 4.47917
const fallbackLocation = LatLng(51.9225, 4.47917);
```

**Acceptance criteria:** If location permission is denied or unavailable,
the app continues with Rotterdam as the default city. No blocking errors.

---

## FIX 7 — Ensure dev/test screens are unreachable in production
**Priority: MEDIUM — clean production build**

Confirm that these screens are NOT accessible from any navigation route
in the production build:
- `PerformanceTestScreen`
- `PlacesTestScreen`
- `ultimate_performance_dashboard`

If any of these are accessible via the router, wrap them in a debug guard:

```dart
// Only accessible in debug builds
if (kDebugMode) {
  GoRoute(
    path: '/dev/performance-test',
    builder: (_, __) => const PerformanceTestScreen(),
  ),
}
```

**Acceptance criteria:** In a release build, none of these screens are
accessible. They do not appear in any menu or navigation path.

---

## WHAT NOT TO DO

```
✗ Do NOT change any UI design or colors in these fixes
✗ Do NOT refactor working features
✗ Do NOT touch archived files
✗ Do NOT delete any files
✗ Do NOT add new Supabase tables or columns
✗ Do NOT change navigation routes except to guard dev screens
```

---

## AFTER ALL FIXES — QA CHECKLIST

```
[ ] Open MyDay — no RangeError text visible anywhere
[ ] Scroll MyDay — no yellow overflow warnings
[ ] Settings screen — "Account verwijderen" visible in red
[ ] Tap "Account verwijderen" — confirmation dialog appears
[ ] Confirm deletion — signs out and navigates to login
[ ] Help & Support — "Privacybeleid" row visible
[ ] Tap "Privacybeleid" — opens browser (URL can be placeholder for now)
[ ] Deny location permission on fresh install — app continues with Rotterdam
[ ] Info.plist — every permission has a clear description
[ ] Release build — dev/test screens not accessible
[ ] Test on iPhone SE (small) — no layout overflows
[ ] Test on iPhone 15 Pro Max (large) — no layout overflows
```

---

## ONE MANUAL STEP FOR EDVIENNE (not code)

**Enable leaked password protection in Supabase:**
1. Go to https://supabase.com/dashboard/project/oojpipspxwdmiyaymldo
2. Authentication → Settings → Password
3. Enable "Check for leaked passwords (HaveIBeenPwned)"
4. Save

This cannot be done via code — it must be toggled in the dashboard.
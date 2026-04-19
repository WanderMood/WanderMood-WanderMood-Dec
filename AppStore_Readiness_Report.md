# 🍎 App Store Readiness Report — WanderMood
**Audit Date:** April 17, 2026  
**App Version:** 1.0.0+26 (pubspec.yaml)  
**Bundle ID:** com.edviennemer.wandermood  
**Platform:** Flutter (iOS)

---

## Summary

WanderMood has a solid foundation — privacy manifest is thorough, app icons are complete, permissions are properly described, delete-account is implemented, and the build pipeline is well-structured. However, there are **4 critical issues** that will either cause App Store rejection or expose live users to security/data risks. There are also **5 important warnings** that are strong rejection risks. None of these require touching your app logic — they are configuration, security hygiene, and metadata tasks.

---

## ❌ Critical Issues — Fix Before Submitting

### 1. Hardcoded API Keys Baked Into the Release Binary

**Files:** `lib/core/constants/api_keys.dart`, `ios/Runner/AppDelegate.swift`

Your fallback API keys are hardcoded as Dart `const` values with **no** `kDebugMode` guard. This means they are compiled directly into the release IPA and extractable by anyone who downloads your app.

Exposed keys:
- **Google Places key** — `AIzaSyDOZgpNquJFfd2Hqp_DUd8xQJc-W-lbRXs` (hardcoded as `_defaultGooglePlacesKey`)
- **Google Maps key** — `AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k` (hardcoded in `AppDelegate.swift` as a string literal fallback AND in `api_keys.dart` inside `if (kDebugMode)` — the AppDelegate one is NOT guarded)
- **OpenWeather key** — `d158323777e324a2537591bc7fa6ca17` (hardcoded as `_defaultOpenWeatherKey`)
- **Supabase URL + Anon Key** — full URL and JWT hardcoded as `_defaultSupabaseUrl` / `_defaultSupabaseAnonKey`

**What to fix:**

In `api_keys.dart`, wrap all fallbacks:
```dart
static String get googlePlacesKey {
  const buildKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  if (buildKey.isNotEmpty && buildKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
    return buildKey;
  }
  // ONLY in debug mode:
  if (kDebugMode) return 'AIzaSyDOZgpNquJFfd2Hqp_DUd8xQJc-W-lbRXs';
  throw Exception('GOOGLE_PLACES_API_KEY not set for release build');
}
```

In `AppDelegate.swift`, remove the `manifestAlignedFallback` literal entirely. If `plistKey` is empty in release, let it fail gracefully rather than shipping a real key.

**Why this matters:** Google and Supabase abuse detection can lock your project if keys leak. The Supabase anon key lets anyone call your database API. Apple won't reject for this, but your backend gets compromised.

---

### 2. Version Number Inconsistency (Will Cause Upload Failure)

**File:** `ios/Runner.xcodeproj/project.pbxproj`

Your Xcode project has conflicting values across build configurations:

| Setting | Debug | Profile | Release |
|---|---|---|---|
| `MARKETING_VERSION` | `1.0.0` | `1.0` | `1.0` |
| `CURRENT_PROJECT_VERSION` | `6` | `1` | `6` |

Your `pubspec.yaml` says `version: 1.0.0+26` — but Xcode shows build numbers of `6` and `1`, not `26`.

App Store Connect will reject an upload where build numbers don't match or have already been used. `MARKETING_VERSION` inconsistency (`1.0` vs `1.0.0`) causes display issues in the App Store.

**What to fix:**
- Set `MARKETING_VERSION = 1.0.0` uniformly across all configurations
- Set `CURRENT_PROJECT_VERSION = 26` (matching the `+26` in pubspec) across all configurations
- Or use `flutter build ipa` which auto-injects these from pubspec — but verify the pbxproj values are also updated

---

### 3. Missing `NSPhotoLibraryAddUsageDescription` in Info.plist

**File:** `ios/Runner/Info.plist`

Your app uses `image_picker` to pick photos from the gallery **and** camera, and uses `share_plus` with `shareXFiles` to share files. On iOS, if any image path leads to the photo library being written to (e.g. a user saves a shared image), the system requires `NSPhotoLibraryAddUsageDescription`.

You have `NSPhotoLibraryUsageDescription` (reading), but not `NSPhotoLibraryAddUsageDescription` (writing/saving). The `image_picker` camera capture flow on iOS 14+ may trigger a save-to-photos flow depending on plugin version, and its absence causes a **crash** at runtime on real devices.

**What to fix** — add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>WanderMood saves your travel photos to your library when you choose to keep them.</string>
```

---

### 4. In-App Purchase / Premium Screen Not StoreKit-Connected

**File:** `lib/features/profile/presentation/screens/premium_upgrade_screen.dart`

Your `PremiumUpgradeScreen` exists and is user-facing, with comments referencing StoreKit and Stripe Checkout. However, the code shows no active StoreKit/`in_app_purchase` plugin integration. If the screen shows pricing and a purchase CTA that doesn't go through Apple IAP, Apple will reject under **Guideline 3.1.1**.

**What to fix (two valid paths):**
- **Path A (recommended):** Integrate the `in_app_purchase` Flutter plugin and process purchases through StoreKit. Set up products in App Store Connect.
- **Path B (short-term):** If premium is not yet live, remove the premium upgrade screen from the release build entirely (or show a "Coming soon" state with no pricing displayed). Do not show prices without StoreKit.

Note: the comment in the file says "App Store-safe: no fake purchases in-app" — this is only true if the screen makes **no purchase attempt**. If it shows pricing and a "Get Premium" button that does nothing, reviewers will flag it for incomplete functionality.

---

## ⚠️ Warnings — Strong Rejection Risks

### 5. Sign In with Apple Entitlement Not Visible

**File:** No `.entitlements` file found in `ios/Runner/`

Your app uses `sign_in_with_apple` (confirmed in `social_auth_service.dart`). This requires the `com.apple.developer.applesignin` entitlement in your `.entitlements` file AND the capability enabled in App Store Connect. No entitlements file was found in the scanned directory.

**What to check:** In Xcode → Target Runner → Signing & Capabilities — verify "Sign In with Apple" capability is added. This auto-generates the entitlements file. If it's missing at runtime, Sign In with Apple calls will silently fail or crash.

---

### 6. Push Notifications Entitlement Likely Missing

**Files:** `pubspec.yaml` includes `flutter_local_notifications`, `lib/core/services/notification_service.dart` exists

Local notifications on iOS require the `aps-environment` entitlement. Without it, notification permission requests fail silently on real devices (TestFlight and App Store builds specifically — it works on simulator without it).

**What to check:** In Xcode → Signing & Capabilities → add "Push Notifications" capability. This adds `aps-environment: production` to the entitlements file for release builds.

---

### 7. Incomplete Features Visible to Reviewers

**Files:** Multiple

Apple reviewers test the app manually and reject for "features that don't work":

- `lib/core/services/wandermood_ai_service.dart:13` — `TODO: Remove this class once createDayPlan, optimizeItinerary...` — dead/deprecated code still referenced
- `lib/features/plans/domain/notifiers/plan_generation_notifier.dart:83` — `userId: 'temp_user_id'` — hardcoded placeholder; plan creation will fail for all real users
- `lib/features/home/presentation/screens/dynamic_my_day_screen.dart:2316` — `TODO: Open rating dialog` — a UI tap with no action, looks broken to reviewers
- `lib/core/services/smart_prefetch_manager.dart:241-290` — mock/stub data returned as real content when API fails; reviewers may see placeholder data

**What to fix:** The `temp_user_id` is the most dangerous — fix before submitting. The others should be hidden or completed.

---

### 8. Copious `debugPrint` of PII in Production Builds

**File:** `lib/main.dart` and throughout

Your app `debugPrint`s user IDs, session state, auth tokens, and email addresses in production builds (these calls are not wrapped in `kDebugMode`). While Apple won't reject for this, it violates Apple's privacy guidelines for data handling and could surface in a privacy review. On iOS, `debugPrint` output appears in device Console logs and is readable by any app with the right entitlement.

**What to fix:** Wrap all sensitive `debugPrint` calls in `if (kDebugMode) { ... }`. Specifically the ones in `_synchronizeAuthState()` that print `user.id` and session info.

---

### 9. Deployment Target Inconsistency

**Files:** `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`

- Podfile: `platform :ios, '14.0'`
- Xcode project: `IPHONEOS_DEPLOYMENT_TARGET = 14.0` in some configs, `15.6` in others

A mismatch between the Podfile platform and Xcode deployment target can cause CocoaPods linker warnings that sometimes surface as App Store validation errors. Apple's current minimum for **new app submissions** is iOS 16 (as of Spring 2024).

**What to fix:**
1. Decide on one deployment target (iOS 16 recommended for new submissions)
2. Update Podfile: `platform :ios, '16.0'`
3. Update all Xcode configurations to `IPHONEOS_DEPLOYMENT_TARGET = 16.0`

---

## ✅ Passing Checks

- **Privacy Manifest** (`PrivacyInfo.xcprivacy`) — present and correctly declares all 4 required-reason API categories (FileTimestamp, UserDefaults, DiskSpace, SystemBootTime) with valid reason codes
- **App Icons** — complete set present including 1024×1024 marketing icon; `remove_alpha_ios: true` in pubspec ensures no transparent icon rejection
- **Permission Strings** — location (when in use + always), camera, photos (read), microphone, and speech recognition all have user-facing, meaningful descriptions
- **ITSAppUsesNonExemptEncryption = false** — correctly declared; no export compliance forms needed
- **Delete Account** — fully implemented with localization across EN/NL/DE/ES/FR; satisfies App Store requirement for apps with account creation
- **Privacy Policy & Terms URLs** — defined and hosted at `wandermood-landing.vercel.app`
- **Deep Links** — custom URL schemes (`io.supabase.wandermood` and `wandermood://`) registered in Info.plist; handled in AppDelegate and main.dart
- **debugShowCheckedModeBanner: false** — confirmed in MaterialApp.router; no debug banner visible to reviewers
- **ExportOptions.plist** — correctly configured: `method: app-store`, bitcode disabled, team ID set
- **Launch Screen** — `LaunchScreen.storyboard` present; green background with centered logo matches app branding
- **Sign In with Apple offered** — app supports Apple sign-in alongside Google, satisfying Guideline 4.8 (both must be offered if either is)
- **Build script** (`build_testflight.sh`) — correctly uses `--dart-define` flags; enforces required keys
- **`ITSAppUsesNonExemptEncryption`** — `false`; no additional encryption documentation required

---

## 📋 App Store Connect Checklist (Outside the Codebase)

These items cannot be verified from code but are required for submission:

- [ ] **App record created** in App Store Connect with bundle ID `com.edviennemer.wandermood`
- [ ] **App screenshots** prepared for: iPhone 6.7" (iPhone 15 Pro Max), iPhone 6.5" (iPhone 14 Plus), iPhone 5.5" (iPhone 8 Plus), and iPad 12.9" (if supporting iPad)
- [ ] **App name:** "Wandermood" or "WanderMood" — check trademark, max 30 characters
- [ ] **Subtitle** — optional, max 30 characters
- [ ] **Description** — max 4000 characters, no mentions of other platforms (Android, Google Play)
- [ ] **Keywords** — max 100 characters total; do not repeat the app name
- [ ] **Support URL** — must be a live, reachable webpage
- [ ] **Privacy Policy URL** — `https://wandermood-landing.vercel.app/en/privacy` — verify this URL is live and returns a real policy page
- [ ] **Age Rating** — complete the questionnaire in App Store Connect; "no alcohol/gambling/adult content" selections expected based on app features
- [ ] **Content Rights** — confirm you own or have rights to all assets, music, and Unsplash photos used
- [ ] **In-App Purchases** — if adding premium via StoreKit, create IAP products in App Store Connect and link them before submission
- [ ] **App Review notes** — include test credentials (email + magic link flow) so reviewers can log in
- [ ] **Category** — suggest: Travel (primary), Lifestyle (secondary)

---

## Recommended Fix Order

**Before writing a single line of code — verify:**
1. The legal URLs (`/en/privacy`, `/en/terms`, `/en/account-deletion`) are live and return real content. Apple checks these.

**Code fixes — in priority order:**

1. **Fix `temp_user_id`** in `plan_generation_notifier.dart` — will cause data corruption for real users (30 min)
2. **Add `NSPhotoLibraryAddUsageDescription`** to Info.plist — prevents runtime crash (5 min)
3. **Fix version numbers** in Xcode — `MARKETING_VERSION = 1.0.0`, `CURRENT_PROJECT_VERSION = 26` (10 min)
4. **Guard hardcoded API keys** with `kDebugMode` — security hygiene (1 hour)
5. **Remove AppDelegate.swift hardcoded fallback key** — most dangerous exposed key (10 min)
6. **Add/verify entitlements file** in Xcode for Sign In with Apple + Push Notifications (20 min)
7. **Address Premium screen** — either connect StoreKit or hide the CTA (variable)
8. **Wrap sensitive debugPrint calls** in `kDebugMode` (1 hour)
9. **Align deployment target** across Podfile and Xcode to iOS 16 (15 min)

**Then:** Build a clean release IPA, test on a physical device via TestFlight, and submit.

---

*Report generated by the `ios-appstore-readiness` skill. No code was modified during this audit.*

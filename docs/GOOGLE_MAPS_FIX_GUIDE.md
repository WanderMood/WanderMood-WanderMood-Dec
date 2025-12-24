# Google Maps Fix Guide

## Problem
Map view shows grey map with pins and Google logo, but no actual map tiles are rendered.

## Root Causes
This typically happens when:
1. **API Key Issues**:
   - Maps SDK for iOS/Android not enabled for the API key
   - API key restrictions don't match app bundle ID/package name
   - Invalid or expired API key
   - Billing not enabled on Google Cloud project

2. **Configuration Issues**:
   - API key not properly set in native files
   - Bundle ID (iOS) or package name (Android) mismatch
   - Network connectivity issues

## Current Configuration

### iOS: `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k")
```

### Android: `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k" />
```

## Step-by-Step Fix

### Step 1: Verify API Key in Google Cloud Console

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project**
3. **Check API Key**:
   - Go to **APIs & Services** → **Credentials**
   - Find the key: `AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k`
   - Click on it to view details

4. **Verify APIs Enabled**:
   - The key must have **Maps SDK for iOS** enabled (for iOS)
   - The key must have **Maps SDK for Android** enabled (for Android)
   - Check **APIs & Services** → **Enabled APIs** to see what's enabled

5. **Check Restrictions**:
   - **API restrictions**: Should include "Maps SDK for iOS" and/or "Maps SDK for Android"
   - **Application restrictions**:
     - **iOS**: Bundle ID should be `io.supabase.wandermood` (or your actual bundle ID)
     - **Android**: Package name should match your app's package name

### Step 2: Enable Required APIs

If APIs are not enabled:

1. Go to **APIs & Services** → **Library**
2. Search for and enable:
   - **Maps SDK for iOS** (for iOS builds)
   - **Maps SDK for Android** (for Android builds)
   - **Places API** (if using same key for places)

### Step 3: Verify Billing

Google Maps requires billing to be enabled:

1. Go to **Billing** in Google Cloud Console
2. Ensure billing account is linked and active
3. Check for any billing alerts or issues

### Step 4: Check Bundle ID / Package Name

#### iOS Bundle ID
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select **Runner** target
3. Go to **General** tab
4. Check **Bundle Identifier** (should match API key restrictions)

#### Android Package Name
1. Open `android/app/build.gradle` or `android/app/build.gradle.kts`
2. Check `applicationId` (should match API key restrictions)

### Step 5: Test with Diagnostic Logging

The app now includes enhanced logging. Check console output for:
- `✅ Google Map created successfully` - Map widget initialized
- `📍 Initial position: ...` - Camera position set
- `📍 Markers count: ...` - Markers loaded
- `🗺️ Camera idle - map should be fully loaded` - Map fully rendered

If you see these logs but still grey map, it's likely an API key issue.

### Step 6: Update API Key (If Needed)

If you need to use a different API key:

#### iOS Update
Edit `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_NEW_API_KEY_HERE")
```

#### Android Update
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_NEW_API_KEY_HERE" />
```

### Step 7: Rebuild and Test

After making changes:
```bash
flutter clean
flutter pub get
flutter build ios  # or flutter build android
```

## Quick Diagnostic Checklist

- [ ] API key has **Maps SDK for iOS** enabled (for iOS)
- [ ] API key has **Maps SDK for Android** enabled (for Android)
- [ ] Bundle ID (iOS) matches API key restrictions
- [ ] Package name (Android) matches API key restrictions
- [ ] Billing is enabled on Google Cloud project
- [ ] API key is correctly pasted (no extra spaces/characters)
- [ ] Network connectivity is working
- [ ] App has location permissions (if using myLocationEnabled)

## Common Error Messages

### "This API key is not authorized"
- **Fix**: Enable Maps SDK for iOS/Android in Google Cloud Console

### "API key not valid"
- **Fix**: Check if key is correct, not expired, and has proper restrictions

### "This API key is restricted"
- **Fix**: Check bundle ID/package name matches restrictions, or remove restrictions temporarily for testing

### Maps load but show grey tiles
- **Fix**: Usually billing issue or API not enabled. Check billing status and enabled APIs.

## Testing

1. **Run on physical device** (simulators sometimes have issues)
2. **Check Xcode/Android Studio console** for error messages
3. **Verify network connectivity** (maps need internet)
4. **Test with location permissions** granted

## Alternative: Use Same Key for Maps and Places

If your Google Places API key has Maps SDK enabled, you can use the same key:

1. Check if your Places API key (`GOOGLE_PLACES_API_KEY` from .env) has Maps SDK enabled
2. If yes, update native files to use that key instead
3. This simplifies key management

## Next Steps After Fix

Once maps are working:
1. Test map interactions (tap markers, zoom, pan)
2. Verify markers show correctly
3. Test location features
4. Monitor Google Cloud Console for usage

## Support

If maps still don't work after following this guide:
1. Check Google Cloud Console for error logs
2. Verify API key in Google Cloud Console
3. Test with a new unrestricted API key (temporarily) to isolate the issue
4. Check Xcode/Android Studio console for native errors




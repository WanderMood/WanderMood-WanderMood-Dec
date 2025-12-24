# Google Maps Diagnostic & Fix

## Current Issue
Map view shows grey map with pins and Google logo, but no actual map tiles are rendered.

## Quick Diagnostic Steps

### 1. Check Current API Key
**Current key in code**: `AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k`

**Location**:
- iOS: `ios/Runner/AppDelegate.swift` (line 12)
- Android: `android/app/src/main/AndroidManifest.xml` (line 55)

### 2. Verify in Google Cloud Console

1. **Go to**: https://console.cloud.google.com/
2. **Navigate to**: APIs & Services → Credentials
3. **Find key**: `AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k`
4. **Check**:
   - ✅ Is "Maps SDK for iOS" enabled? (for iOS builds)
   - ✅ Is "Maps SDK for Android" enabled? (for Android builds)
   - ✅ Are API restrictions correct?
   - ✅ Are application restrictions (bundle ID/package) correct?
   - ✅ Is billing enabled?

### 3. Check Enabled APIs

Go to **APIs & Services** → **Enabled APIs** and verify:
- Maps SDK for iOS
- Maps SDK for Android
- Places API (if using same key)

### 4. Check Bundle ID / Package Name

**iOS Bundle ID**: Check in Xcode → Runner target → General → Bundle Identifier
**Android Package**: Check in `android/app/build.gradle` → `applicationId`

These must match the API key restrictions in Google Cloud Console.

### 5. Test with Enhanced Logging

The app now includes diagnostic logging. When you open the map view, check console for:
- `✅ Google Map created successfully` - Map widget initialized
- `📍 Initial position: ...` - Camera position
- `📍 Markers count: ...` - Number of markers
- `🗺️ Camera idle - map should be fully loaded` - Map fully rendered

## Most Likely Issues

### Issue 1: Maps SDK Not Enabled
**Symptom**: Grey map, no tiles
**Fix**: Enable "Maps SDK for iOS" and/or "Maps SDK for Android" in Google Cloud Console

### Issue 2: API Key Restrictions
**Symptom**: Grey map, no tiles
**Fix**: Check bundle ID/package name matches restrictions, or temporarily remove restrictions for testing

### Issue 3: Billing Not Enabled
**Symptom**: Grey map, no tiles
**Fix**: Enable billing in Google Cloud Console (Maps requires billing)

### Issue 4: Wrong API Key
**Symptom**: Grey map, no tiles
**Fix**: Verify the key in native files matches the key in Google Cloud Console

## Quick Fix Options

### Option A: Use Same Key as Places API
If your `GOOGLE_PLACES_API_KEY` (from .env) has Maps SDK enabled:

1. Check your Places API key in Google Cloud Console
2. If it has Maps SDK enabled, update native files to use that key:
   - iOS: `ios/Runner/AppDelegate.swift`
   - Android: `android/app/src/main/AndroidManifest.xml`

### Option B: Create New Key with Maps SDK
1. Go to Google Cloud Console
2. Create new API key
3. Enable: Maps SDK for iOS, Maps SDK for Android, Places API
4. Update native files with new key
5. Rebuild app

### Option C: Remove Restrictions Temporarily
For testing only:
1. Go to Google Cloud Console → Credentials
2. Edit the API key
3. Set "API restrictions" to "Don't restrict key"
4. Set "Application restrictions" to "None"
5. Test if maps load
6. If they do, add restrictions back properly

## Files to Update

1. **iOS**: `ios/Runner/AppDelegate.swift`
   ```swift
   GMSServices.provideAPIKey("YOUR_KEY_HERE")
   ```

2. **Android**: `android/app/src/main/AndroidManifest.xml`
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_KEY_HERE" />
   ```

## After Making Changes

```bash
flutter clean
flutter pub get
flutter build ios  # or flutter build android
```

## Testing Checklist

- [ ] API key has Maps SDK enabled
- [ ] Bundle ID/package name matches restrictions
- [ ] Billing is enabled
- [ ] Key is correctly pasted (no spaces)
- [ ] App rebuilt after changes
- [ ] Tested on physical device (not just simulator)
- [ ] Network connectivity working
- [ ] Check console logs for errors

## Next Steps

1. **Verify API key configuration** in Google Cloud Console
2. **Check enabled APIs** match requirements
3. **Test with diagnostic logging** to see what's happening
4. **Update native files** if key needs to change
5. **Rebuild and test** on physical device




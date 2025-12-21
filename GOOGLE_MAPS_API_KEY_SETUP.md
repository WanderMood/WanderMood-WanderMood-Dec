# How to Add Your Google Maps API Key

## Current Status

Your Google Maps API key is currently **hardcoded** in two places:
- **iOS**: `ios/Runner/AppDelegate.swift` → `AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k`
- **Android**: `android/app/src/main/AndroidManifest.xml` → `AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k`

## Important Note

⚠️ **Google Maps API key and Google Places API key can be the SAME key!**

If your Google Cloud API key has both **Maps SDK for iOS/Android** and **Places API** enabled, you can use the same key for both. This is the recommended approach.

## Step 1: Get Your Google Maps API Key

### Option A: Use Existing Key (If You Have One)

If you already have a Google Cloud API key with Maps SDK enabled, use that same key.

### Option B: Create a New Key

1. Go to: https://console.cloud.google.com/
2. Select your project (or create one)
3. Enable required APIs:
   - **Maps SDK for iOS** (for iOS app)
   - **Maps SDK for Android** (for Android app)
   - **Places API** (for places features)
   - **Maps JavaScript API** (optional, for web features)
4. Create API Key:
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **API Key**
   - Copy the key
5. Restrict the key (recommended):
   - Click on the key to edit
   - Under **API restrictions**, select **Restrict key**
   - Choose: **Maps SDK for iOS**, **Maps SDK for Android**, **Places API**
   - Under **Application restrictions**:
     - For iOS: Add your bundle ID (e.g., `io.supabase.wandermood`)
     - For Android: Add your package name and SHA-1 certificate fingerprint

## Step 2: Update iOS Configuration

### File: `ios/Runner/AppDelegate.swift`

Replace the hardcoded key on line 12:

```swift
// BEFORE:
GMSServices.provideAPIKey("AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k")

// AFTER (replace with your actual key):
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
```

**Full file location:**
```
ios/Runner/AppDelegate.swift
```

## Step 3: Update Android Configuration

### File: `android/app/src/main/AndroidManifest.xml`

Replace the hardcoded key on line 55:

```xml
<!-- BEFORE: -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k" />

<!-- AFTER (replace with your actual key): -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```

**Full file location:**
```
android/app/src/main/AndroidManifest.xml
```

## Step 4: (Optional) Use Environment Variable

For better security, you can use environment variables instead of hardcoding:

### iOS - Using Info.plist

1. Open `ios/Runner/Info.plist`
2. Add:
```xml
<key>GMSApiKey</key>
<string>$(GOOGLE_MAPS_API_KEY)</string>
```
3. In Xcode, go to **Build Settings** → **User-Defined**
4. Add `GOOGLE_MAPS_API_KEY` with your key value

### Android - Using build.gradle

1. Open `android/app/build.gradle.kts`
2. Add to `android.defaultConfig`:
```kotlin
manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = project.findProperty("GOOGLE_MAPS_API_KEY") as String? ?: ""
```
3. In `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />
```
4. Create `android/local.properties`:
```properties
GOOGLE_MAPS_API_KEY=your_key_here
```

## Quick Setup (Recommended for Now)

For simplicity, just replace the hardcoded keys directly:

### 1. Update iOS
```bash
# Edit ios/Runner/AppDelegate.swift
# Replace line 12 with your key
```

### 2. Update Android
```bash
# Edit android/app/src/main/AndroidManifest.xml
# Replace line 55 with your key
```

### 3. Rebuild
```bash
flutter clean
flutter pub get
flutter build ios  # or flutter build android
```

## Verification

After updating, test the app:

1. **iOS**: Run on device/simulator and check if maps load
2. **Android**: Run on device/emulator and check if maps load
3. **Check logs** for any API key errors

## Common Issues

### "API key not valid"
- Verify the key has **Maps SDK for iOS** and **Maps SDK for Android** enabled
- Check if key restrictions are blocking your app
- Verify bundle ID (iOS) or package name (Android) matches restrictions

### "This API key is not authorized"
- Enable the required APIs in Google Cloud Console
- Check API restrictions on the key
- Verify billing is enabled (Google Maps requires billing)

### Maps not loading
- Check network connectivity
- Verify API key is correctly pasted (no extra spaces)
- Check Xcode/Android Studio console for error messages

## Best Practices

✅ **Do:**
- Use the same key for both Maps and Places (if both APIs are enabled)
- Restrict the key to specific APIs
- Add application restrictions (bundle ID/package name)
- Monitor usage in Google Cloud Console
- Keep keys secure (don't commit to public repos)

❌ **Don't:**
- Use unrestricted keys in production
- Share keys publicly
- Use different keys unnecessarily
- Forget to enable billing

## Summary

**Files to update:**
1. ✅ `ios/Runner/AppDelegate.swift` (line 12)
2. ✅ `android/app/src/main/AndroidManifest.xml` (line 55)

**Key to use:**
- Same key as Google Places API (if both APIs enabled)
- Or create a separate key with Maps SDK enabled

**After updating:**
- Run `flutter clean && flutter pub get`
- Rebuild the app
- Test maps functionality


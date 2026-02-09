# .env File Setup Guide for WanderMood

## 📋 Overview

The WanderMood app uses a `.env` file to securely store API keys and configuration. This file is **NOT** committed to git (it's in `.gitignore`) to protect your sensitive credentials.

## 🔧 How It Works

### 1. **Package Used**
- **`flutter_dotenv`** (version 5.1.0) - Loads environment variables from `.env` file

### 2. **Loading Process**
The `.env` file is loaded in `lib/main.dart` at app startup:

```dart
// Load environment variables FIRST before any API key access
try {
  await dotenv.load(fileName: '.env');
  debugPrint('✅ Loaded .env file');
} catch (e) {
  debugPrint('⚠️ Could not load .env file: $e');
  // Continue - will use build-time environment variables or fallbacks
}
```

### 3. **Priority Order**
The app uses a **fallback chain** for each API key:
1. **`.env` file** (highest priority)
2. **Build-time environment variables** (`--dart-define`)
3. **Hardcoded fallbacks** (development only)

This means if `.env` is missing, the app will still work using fallback values (in debug mode).

## 📝 Required Environment Variables

Create a `.env` file in the **project root** (`/Users/edviennemerencia/WanderMood-WanderMood-Dec/.env`) with these variables:

```env
# Supabase Configuration (REQUIRED)
SUPABASE_URL=https://ymxehzmgeqccuvbvjwtq.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Google APIs (REQUIRED)
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# OpenAI (OPTIONAL - will use mock responses if not set)
OPENAI_API_KEY=your_openai_api_key_here

# OpenWeather (OPTIONAL - has fallback for development)
OPENWEATHER_API_KEY=your_openweather_api_key_here
```

## ✅ Setup Steps

### Step 1: Create `.env` File

1. Navigate to your project root:
   ```bash
   cd /Users/edviennemerencia/WanderMood-WanderMood-Dec
   ```

2. Create the `.env` file:
   ```bash
   touch .env
   ```

3. Open it in your editor and add your API keys (see format above)

### Step 2: Verify `pubspec.yaml`

Make sure `.env` is listed in the `assets` section:

```yaml
flutter:
  assets:
    - .env  # ← This line must exist
    - assets/images/
    # ... other assets
```

**✅ Already fixed!** The `.env` file is now in the assets section.

### Step 3: Get Your API Keys

#### Supabase Keys
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

#### Google API Keys
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable these APIs:
   - **Places API**
   - **Maps SDK for iOS**
   - **Maps SDK for Android**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy the key to both:
   - `GOOGLE_PLACES_API_KEY` (for Flutter code)
   - `GOOGLE_MAPS_API_KEY` (for reference - must also be in native files)

#### OpenAI Key (Optional)
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Go to **API Keys**
3. Create a new secret key
4. Copy to `OPENAI_API_KEY`

#### OpenWeather Key (Optional)
1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Get your API key from the dashboard
4. Copy to `OPENWEATHER_API_KEY`

### Step 4: Update Native Files (Google Maps)

**Important:** `GOOGLE_MAPS_API_KEY` from `.env` is **NOT automatically used** by native iOS/Android code. You must also set it in:

#### iOS: `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
```

#### Android: `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```

**Tip:** You can use the same key for both `GOOGLE_PLACES_API_KEY` and `GOOGLE_MAPS_API_KEY` if your Google Cloud API key has both APIs enabled.

### Step 5: Verify Setup

1. Run `flutter pub get` to ensure dependencies are installed
2. Run the app: `flutter run`
3. Check the console logs for:
   - `✅ Loaded .env file` - Success!
   - `⚠️ Could not load .env file` - Check file path and format

## 🔍 How Variables Are Used

### In Code (`lib/core/constants/api_keys.dart`)

Each API key has a getter that follows the priority chain:

```dart
static String get googlePlacesKey {
  // 1. Try .env file first
  try {
    final envKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
  } catch (e) {
    // dotenv not loaded, continue...
  }
  
  // 2. Try build-time environment variable
  final buildKey = const String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  if (buildKey.isNotEmpty) {
    return buildKey;
  }
  
  // 3. Fallback (development only)
  if (kDebugMode) {
    return 'fallback_key_here';
  }
  
  throw Exception('GOOGLE_PLACES_API_KEY not found');
}
```

### Usage Example

```dart
import 'package:wandermood/core/constants/api_keys.dart';

// Get API key (automatically uses .env if available)
final apiKey = ApiKeys.googlePlacesKey;
```

## 🚨 Troubleshooting

### Problem: "Could not load .env file"

**Solutions:**
1. ✅ Check `.env` file exists in project root
2. ✅ Check `.env` is listed in `pubspec.yaml` assets
3. ✅ Check file format (no spaces around `=`, one variable per line)
4. ✅ Run `flutter clean && flutter pub get`

### Problem: "API key not found" error

**Solutions:**
1. ✅ Check variable name matches exactly (case-sensitive)
2. ✅ Check no extra spaces or quotes in `.env` file
3. ✅ Verify the key is set: `dotenv.env['VARIABLE_NAME']`

### Problem: App works but uses fallback keys

**Solutions:**
1. ✅ Check console logs for `.env` loading messages
2. ✅ Verify `.env` file format is correct
3. ✅ Make sure you're running from the project root

### Problem: Google Maps not working

**Solutions:**
1. ✅ `.env` file only works for Flutter code
2. ✅ You **must** also set the key in native files:
   - `ios/Runner/AppDelegate.swift`
   - `android/app/src/main/AndroidManifest.xml`

## 📚 Additional Resources

- [flutter_dotenv Documentation](https://pub.dev/packages/flutter_dotenv)
- [Supabase Setup Guide](./SUPABASE_SETUP_GUIDE.md)
- [Google Places Setup Guide](./GOOGLE_PLACES_SETUP.md)
- [Environment Variables Explanation](./ENV_FILE_EXPLANATION.md)

## 🔒 Security Notes

1. **Never commit `.env` to git** - It's in `.gitignore`
2. **Use different keys for development/production**
3. **Rotate keys regularly**
4. **Don't share `.env` files** - Each developer should create their own
5. **For production builds**, use `--dart-define` instead of `.env` file

## ✅ Checklist

- [ ] `.env` file created in project root
- [ ] `.env` added to `pubspec.yaml` assets
- [ ] All required API keys added to `.env`
- [ ] Google Maps key added to native files (iOS & Android)
- [ ] `flutter pub get` run successfully
- [ ] App runs and logs show "✅ Loaded .env file"
- [ ] API features work correctly

---

**Last Updated:** January 15, 2026

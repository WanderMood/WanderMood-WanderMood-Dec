# Build Commands for TestFlight and Device Testing

## Required Environment Variables

The app requires these API keys to function:
- `SUPABASE_URL` (CRITICAL - app won't work without this)
- `SUPABASE_ANON_KEY` (CRITICAL - app won't work without this)
- `GOOGLE_PLACES_API_KEY` (Optional - places features will be limited without this)
- `OPENAI_API_KEY` (Optional - AI features will use mock responses without this)
- `OPENWEATHER_API_KEY` (Optional - weather features will be limited without this)

## Key Names Must Match Exactly

✅ **Correct key names:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_PLACES_API_KEY`
- `OPENAI_API_KEY`
- `OPENWEATHER_API_KEY`

❌ **Wrong key names (will NOT work):**
- `SUPABASE_URL_KEY`
- `SUPABASE_ANON`
- `GOOGLE_PLACES_KEY`
- etc.

## Build for Physical Device (Development)

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM

flutter build ios --release \
  --dart-define=SUPABASE_URL=your_supabase_url_here \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key_here \
  --dart-define=GOOGLE_PLACES_API_KEY=your_google_places_key_here \
  --dart-define=OPENAI_API_KEY=your_openai_key_here \
  --dart-define=OPENWEATHER_API_KEY=your_openweather_key_here
```

Then open Xcode and build/run on device:
```bash
open ios/Runner.xcworkspace
```

## Build for TestFlight (Release)

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM

flutter build ipa --release \
  --dart-define=SUPABASE_URL=your_supabase_url_here \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key_here \
  --dart-define=GOOGLE_PLACES_API_KEY=your_google_places_key_here \
  --dart-define=OPENAI_API_KEY=your_openai_key_here \
  --dart-define=OPENWEATHER_API_KEY=your_openweather_key_here
```

## Using a Script (Recommended)

Create a file `build_testflight.sh`:

```bash
#!/bin/bash

# Set your API keys here
export SUPABASE_URL="your_supabase_url_here"
export SUPABASE_ANON_KEY="your_supabase_anon_key_here"
export GOOGLE_PLACES_API_KEY="your_google_places_key_here"
export OPENAI_API_KEY="your_openai_key_here"
export OPENWEATHER_API_KEY="your_openweather_key_here"

# Build for TestFlight
flutter build ipa --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GOOGLE_PLACES_API_KEY="$GOOGLE_PLACES_API_KEY" \
  --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
  --dart-define=OPENWEATHER_API_KEY="$OPENWEATHER_API_KEY"
```

Make it executable:
```bash
chmod +x build_testflight.sh
```

Run it:
```bash
./build_testflight.sh
```

## For Development (Using .env file)

1. Create `.env` file in project root:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
GOOGLE_PLACES_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
OPENWEATHER_API_KEY=your_key_here
```

2. Add `.env` to `.gitignore` (IMPORTANT - don't commit keys!)

3. Run normally:
```bash
flutter run
```

## Verification

After building, check the logs to verify keys are loaded:
- Look for: `✅ All required API keys validated`
- Look for: `🔧 Initializing Supabase with URL: ...`
- If you see: `❌ MISSING REQUIRED API KEYS` - keys are not set correctly

## Troubleshooting

### "Missing API key" error in TestFlight
- Make sure you're using `--dart-define` flags
- Verify key names match exactly (case-sensitive)
- Check that keys are not empty or placeholder values

### "Invalid API key" error
- Verify the actual key values are correct
- Check for extra spaces or quotes in the command
- Ensure keys haven't expired or been rotated

### Keys work in debug but not release
- Debug mode uses fallback keys, release mode requires real keys
- Make sure `--dart-define` flags are included in release builds
- Check that `kDebugMode` checks aren't preventing key access


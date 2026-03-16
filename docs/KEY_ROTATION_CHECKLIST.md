# API key rotation checklist

Keys that were ever in the repo or in `.env` (including before we removed hardcoded fallbacks) should be **rotated** so old values cannot be used.

## 1. Supabase

- **Where:** [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Settings** → **API**
- **Rotate:** Create a new anon key or regenerate if the project supports it. Update any server/Edge Function env that uses the key.
- **Update the app:** Use the new values in:
  - Local: `.env` (SUPABASE_URL, SUPABASE_ANON_KEY) or `run_dev.sh`
  - Release: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- **Note:** Supabase URL does not need rotation; only the anon (and service role, if ever exposed) key.

## 2. OpenAI

- **Where:** [OpenAI API keys](https://platform.openai.com/api-keys)
- **Rotate:** Revoke/delete the old key, create a new one.
- **Update the app:** `.env` (OPENAI_API_KEY) or `--dart-define=OPENAI_API_KEY=...` for release.

## 3. OpenWeather

- **Where:** [OpenWeatherMap API keys](https://home.openweathermap.org/api_keys)
- **Rotate:** Generate a new key or regenerate; disable or delete the old one if possible.
- **Update the app:** `.env` (OPENWEATHER_API_KEY) or `--dart-define=OPENWEATHER_API_KEY=...` for release.

## 4. Google (Places + Maps)

- **Where:** [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**
- **Rotate:** Create new API keys for Places and Maps, restrict them (HTTP referrer, app bundle ID, etc.), then delete or restrict the old keys.
- **Update the app:**
  - Dart: `.env` or `--dart-define`: GOOGLE_PLACES_API_KEY, GOOGLE_MAPS_API_KEY
  - **iOS:** In Xcode, set build setting or Info.plist `GOOGLE_MAPS_API_KEY` (or inject via xcconfig) so the native Google Maps SDK gets the new key.
  - **Android:** Add to `android/local.properties` (create the file if needed):  
  `GOOGLE_MAPS_API_KEY=your_google_maps_key`  
  The app’s `build.gradle.kts` reads this and injects it into the manifest. Do not commit `local.properties`.

## After rotating

- Use **only** the new keys in `.env` and in CI/release builds.
- Do **not** commit `.env` (it should remain in `.gitignore`).
- For release builds, pass keys via `--dart-define` or a secure secrets manager; never ship keys in repo or in app assets.

# Final TestFlight Build - New Supabase Project

## Your New Supabase Project
- **Project ID**: `oojpipspxwdmiyaymldo`
- **Project URL**: `https://oojpipspxwdmiyaymldo.supabase.co`

## Before Building - Complete These Steps

### 1. ✅ Set Up Database Tables (Do this FIRST)
- Go to Supabase Dashboard → SQL Editor
- Run the `supabase/COMPLETE_SETUP.sql` script
- Verify tables are created in Table Editor

### 2. ✅ Get Your API Keys
- In Supabase Dashboard → Settings → API
- Copy:
  - **Project URL**: `https://oojpipspxwdmiyaymldo.supabase.co`
  - **anon public** key

### 3. ✅ Update .env File (for development)
Update your `.env` file:
```env
SUPABASE_URL=https://oojpipspxwdmiyaymldo.supabase.co
SUPABASE_ANON_KEY=your_new_anon_key_here
```

## Build for TestFlight

### Option 1: Using the Script (Easiest)

1. Edit `build_testflight.sh` and add your keys:
```bash
export SUPABASE_URL="https://oojpipspxwdmiyaymldo.supabase.co"
export SUPABASE_ANON_KEY="your_actual_anon_key_here"
```

2. Run:
```bash
./build_testflight.sh
```

### Option 2: Manual Command

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM

flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://oojpipspxwdmiyaymldo.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_actual_anon_key_here \
  --dart-define=GOOGLE_PLACES_API_KEY=your_key_here \
  --dart-define=OPENAI_API_KEY=your_key_here \
  --dart-define=OPENWEATHER_API_KEY=your_key_here
```

## After Building

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Archive**:
   - Product → Archive
   - Wait for archive to complete

3. **Distribute**:
   - Click "Distribute App"
   - Choose "TestFlight & App Store"
   - Follow the prompts

4. **Upload to TestFlight**:
   - The IPA will be uploaded automatically
   - Wait for processing (10-30 minutes)

## Why You Need to Rebuild

- ✅ **Old build** has old/incorrect Supabase keys baked in
- ✅ **New build** will have correct keys from your new project
- ✅ **Database tables** are now set up in your new project
- ✅ **Users can signup/login** once new build is deployed

## Verification Checklist

Before uploading to TestFlight, verify:
- [ ] Database tables created (check Supabase Table Editor)
- [ ] `.env` file updated with new keys
- [ ] Build command includes `--dart-define` flags
- [ ] Build completes successfully
- [ ] Test signup in development build first (optional but recommended)

## Quick Test (Optional)

Before building for TestFlight, test locally:
```bash
flutter run
```

Try signing up - if it works locally, it will work in TestFlight!


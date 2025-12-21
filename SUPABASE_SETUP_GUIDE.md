# Supabase Setup Guide for New Project

## Your Project Details
- **Project ID**: `oojpipspxwdmiyaymldo`
- **Project URL**: `https://oojpipspxwdmiyaymldo.supabase.co`

## Step 1: Verify Your .env File

Make sure your `.env` file has:
```env
SUPABASE_URL=https://oojpipspxwdmiyaymldo.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

## Step 2: Get Your API Keys from Supabase Dashboard

1. Go to https://supabase.com/dashboard
2. Select your project: **Project ID: oojpipspxwdmiyaymldo**
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL**: `https://oojpipspxwdmiyaymldo.supabase.co`
   - **anon public** key (under "Project API keys")

## Step 3: Set Up Database Tables

### Option A: Using Supabase Dashboard (Easiest)

1. In your Supabase project dashboard, go to **SQL Editor** (left sidebar)
2. Click **New Query**
3. Open the file: `supabase/COMPLETE_SETUP.sql` from your project
4. Copy the **entire contents** of that file
5. Paste into the SQL Editor
6. Click **Run** (or press Cmd+Enter)
7. Wait for "Success" message

### Option B: Using MCP (I can help with this)

I can run the SQL migration for you using the Supabase MCP tools, but I need you to confirm:
- Do you want me to run the `COMPLETE_SETUP.sql` script now?
- Or do you prefer to run it manually in the dashboard?

## Step 4: Verify Tables Were Created

After running the SQL, check:
1. Go to **Table Editor** in Supabase dashboard
2. You should see these tables:
   - ✅ `profiles`
   - ✅ `user_preferences`
   - ✅ `scheduled_activities`
   - ✅ `moods`
   - ✅ `activities`
   - ✅ `user_check_ins`
   - ✅ `activity_ratings`
   - ✅ `cached_places`
   - ✅ `user_saved_places`
   - ✅ `weather_cache`

## Step 5: Test the Connection

After setting up:
1. Update your `.env` file with the correct keys
2. Run your Flutter app: `flutter run`
3. Check logs for: `✅ All required API keys validated`
4. Try signing up - should work now!

## Troubleshooting

### "Invalid API key" error
- Double-check the keys in `.env` match exactly what's in Supabase dashboard
- Make sure there are no extra spaces or quotes
- Verify the project URL is correct

### Tables not showing
- Make sure you ran the SQL script in the correct project
- Check the SQL Editor for any error messages
- Verify you're looking at the right project in the dashboard


# Supabase Tables Summary

## Required Tables for WanderMood App

Based on the migration files and app requirements, here are the essential tables that need to be created in your Supabase database:

### 1. **scheduled_activities** ✅ (Migration exists but may not be applied)

**Purpose**: Store user's planned/booked activities for "My Day" and "My Agenda"

**Schema**:
```sql
CREATE TABLE IF NOT EXISTS public.scheduled_activities (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL,
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_confirmed BOOLEAN DEFAULT FALSE,
    tags TEXT,
    payment_type TEXT DEFAULT 'free',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id)
);
```

**RLS Policies**:
- Users can view their own scheduled activities
- Users can insert their own scheduled activities
- Users can update their own scheduled activities
- Users can delete their own scheduled activities

**Indexes**:
- `scheduled_activities_user_id_idx` on `user_id`
- `scheduled_activities_start_time_idx` on `start_time`

**Migration File**: `supabase/migrations/20250715_000000_fix_user_registration.sql` (lines 103-165)

---

### 2. **user_preferences** ✅ (Migration exists)

**Purpose**: Store user app settings, travel preferences, dietary restrictions, and AI personalization data

**Schema**:
```sql
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- App settings
    dark_mode BOOLEAN DEFAULT false,
    use_system_theme BOOLEAN DEFAULT true,
    use_animations BOOLEAN DEFAULT true,
    show_confetti BOOLEAN DEFAULT true,
    show_progress BOOLEAN DEFAULT true,
    
    -- Notification preferences
    trip_reminders BOOLEAN DEFAULT true,
    weather_updates BOOLEAN DEFAULT true,
    
    -- Travel preferences for AI
    mood_preferences JSONB DEFAULT '{}',
    travel_preferences JSONB DEFAULT '{}',
    dietary_restrictions TEXT[] DEFAULT ARRAY[]::TEXT[],
    activity_preferences JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Migration File**: `supabase/migrations/20250713_195440_fix_mood_options.sql` (lines 40-66)

---

### 3. **profiles** ✅ (Migration exists)

**Purpose**: Extended user profile information beyond auth.users

**Schema**:
```sql
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    email TEXT,
    bio TEXT,
    avatar_url TEXT,
    currently_exploring TEXT,
    travel_style TEXT DEFAULT 'adventurous',
    travel_vibes TEXT[] DEFAULT '{"Spontaneous", "Social", "Relaxed"}',
    favorite_mood TEXT DEFAULT 'happy',
    -- ... additional fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Migration File**: `supabase/migrations/20250109_fix_missing_tables_and_relationships.sql` (lines 78-130)

---

### 4. **moods** ✅ (Migration exists)

**Purpose**: Track user mood history for personalization

**Schema**:
```sql
CREATE TABLE IF NOT EXISTS public.moods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mood TEXT NOT NULL,
    activity TEXT,
    energy_level NUMERIC CHECK (energy_level >= 1 AND energy_level <= 10),
    notes TEXT,
    location TEXT,
    weather_condition TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Migration File**: `supabase/migrations/20250713_195440_fix_mood_options.sql` (lines 69-87)

---

### 5. **activities** ✅ (Migration exists)

**Purpose**: Available activities for AI recommendations

**Schema**:
```sql
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT,
    description TEXT,
    mood_tags TEXT[],
    energy_level TEXT,
    -- ... additional fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Migration File**: `supabase/migrations/20250713_195440_fix_mood_options.sql` (lines 90+)

---

## 🔧 How to Apply Migrations

### Option 1: Via Supabase Dashboard (Recommended)

1. Go to your Supabase project: https://supabase.com/dashboard
2. Navigate to **SQL Editor**
3. Copy the SQL from the migration file: `supabase/migrations/20250715_000000_fix_user_registration.sql`
4. Run the SQL to create the `scheduled_activities` table
5. Verify the table exists in **Table Editor**

### Option 2: Via Supabase CLI

```bash
# If you have Supabase CLI installed
supabase db push
```

### Option 3: Manual SQL Execution

Run this SQL in your Supabase SQL Editor:

```sql
-- Copy the entire content from:
-- supabase/migrations/20250715_000000_fix_user_registration.sql
-- (lines 103-165 for scheduled_activities table)
```

---

## ✅ Verification Checklist

After running migrations, verify:

- [ ] `scheduled_activities` table exists
- [ ] `user_preferences` table exists
- [ ] `profiles` table exists
- [ ] `moods` table exists
- [ ] `activities` table exists
- [ ] RLS (Row Level Security) is enabled on all tables
- [ ] Foreign key constraints are properly set
- [ ] Indexes are created for performance

---

## 🐛 Current Issue

**Error from logs**:
```
PostgrestException(message: Could not find the table 'public.scheduled_activities' in the schema cache)
```

**Solution**: Run the migration SQL from `supabase/migrations/20250715_000000_fix_user_registration.sql` in your Supabase SQL Editor to create the table.

---

## 📝 Notes

- The app currently uses **SharedPreferences** as a fallback when Supabase tables don't exist
- Once tables are created, the app will automatically use Supabase instead
- All tables should have RLS enabled for security
- Foreign keys ensure data integrity (cascade delete when user is deleted)






-- ================================================
-- WANDERMOOD COMPREHENSIVE DATABASE SCHEMA FIX
-- ================================================
-- This script fixes all database schema issues to match Flutter models
-- Run this in your Supabase SQL Editor

-- ================================================
-- 1. FIX user_preferences TABLE
-- ================================================

-- Add missing columns to user_preferences table
DO $$
BEGIN
    -- Add moods column (JSONB array)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'moods'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN moods JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added moods column to user_preferences';
    END IF;

    -- Add interests column (JSONB array)  
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'interests'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN interests JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added interests column to user_preferences';
    END IF;

    -- Add travel_styles column (JSONB array)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'travel_styles'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN travel_styles JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added travel_styles column to user_preferences';
    END IF;

    -- Add communication_style column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'communication_style'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN communication_style TEXT DEFAULT 'friendly';
        RAISE NOTICE 'Added communication_style column to user_preferences';
    END IF;

    -- Add home_base column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'home_base'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN home_base TEXT DEFAULT 'Local Explorer';
        RAISE NOTICE 'Added home_base column to user_preferences';
    END IF;

    -- Add social_vibe column (JSONB array)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'social_vibe'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN social_vibe JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added social_vibe column to user_preferences';
    END IF;

    -- Add planning_pace column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'planning_pace'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN planning_pace TEXT DEFAULT 'Same Day Planner';
        RAISE NOTICE 'Added planning_pace column to user_preferences';
    END IF;

    -- Add has_completed_onboarding column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'has_completed_onboarding'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN has_completed_onboarding BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_completed_onboarding column to user_preferences';
    END IF;

    -- Add has_completed_preferences column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'has_completed_preferences'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN has_completed_preferences BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_completed_preferences column to user_preferences';
    END IF;

    -- Add language_preference column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'language_preference'
    ) THEN
        ALTER TABLE public.user_preferences ADD COLUMN language_preference TEXT DEFAULT 'en';
        RAISE NOTICE 'Added language_preference column to user_preferences';
    END IF;

END $$;

-- ================================================
-- 2. ENSURE scheduled_activities TABLE EXISTS WITH CORRECT SCHEMA
-- ================================================

-- Create scheduled_activities table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.scheduled_activities (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    activity_id TEXT NOT NULL,
    name TEXT NOT NULL,  -- Note: this is 'name', not 'activity_name'
    description TEXT,
    image_url TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL,
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_confirmed BOOLEAN DEFAULT FALSE,
    tags TEXT,
    payment_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id)
);

-- Add missing foreign key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'scheduled_activities' 
        AND constraint_name = 'scheduled_activities_user_id_fkey'
    ) THEN
        ALTER TABLE public.scheduled_activities
        ADD CONSTRAINT scheduled_activities_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint to scheduled_activities';
    END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS scheduled_activities_user_id_idx ON public.scheduled_activities(user_id);
CREATE INDEX IF NOT EXISTS scheduled_activities_start_time_idx ON public.scheduled_activities(start_time);
CREATE INDEX IF NOT EXISTS scheduled_activities_user_date_idx ON public.scheduled_activities(user_id, start_time);

-- Enable Row Level Security
ALTER TABLE public.scheduled_activities ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (only if they don't exist)
DO $$
BEGIN
    -- Check if policy exists before creating
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scheduled_activities' 
        AND policyname = 'Users can view their own scheduled activities'
    ) THEN
        CREATE POLICY "Users can view their own scheduled activities"
        ON public.scheduled_activities FOR SELECT
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scheduled_activities' 
        AND policyname = 'Users can insert their own scheduled activities'
    ) THEN
        CREATE POLICY "Users can insert their own scheduled activities"
        ON public.scheduled_activities FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scheduled_activities' 
        AND policyname = 'Users can update their own scheduled activities'
    ) THEN
        CREATE POLICY "Users can update their own scheduled activities"
        ON public.scheduled_activities FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scheduled_activities' 
        AND policyname = 'Users can delete their own scheduled activities'
    ) THEN
        CREATE POLICY "Users can delete their own scheduled activities"
        ON public.scheduled_activities FOR DELETE
        USING (auth.uid() = user_id);
    END IF;
END $$;

-- ================================================
-- 3. CREATE places_cache TABLE FOR MOOD-AWARE CACHING
-- ================================================

-- Create places_cache table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.places_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    query_key TEXT NOT NULL,
    location_lat DOUBLE PRECISION NOT NULL,
    location_lng DOUBLE PRECISION NOT NULL,
    radius INTEGER NOT NULL,
    mood_tags JSONB DEFAULT '[]'::jsonb,  -- This was missing!
    places_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    UNIQUE(query_key, location_lat, location_lng, radius)
);

-- Create indexes for places_cache
CREATE INDEX IF NOT EXISTS places_cache_location_idx ON public.places_cache(location_lat, location_lng);
CREATE INDEX IF NOT EXISTS places_cache_mood_tags_idx ON public.places_cache USING GIN(mood_tags);
CREATE INDEX IF NOT EXISTS places_cache_expires_idx ON public.places_cache(expires_at);

-- Enable Row Level Security for places_cache
ALTER TABLE public.places_cache ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for places_cache (public read, admin write)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'places_cache' 
        AND policyname = 'Public can view places cache'
    ) THEN
        CREATE POLICY "Public can view places cache"
        ON public.places_cache FOR SELECT
        TO authenticated
        USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'places_cache' 
        AND policyname = 'System can manage places cache'
    ) THEN
        CREATE POLICY "System can manage places cache"
        ON public.places_cache FOR ALL
        TO service_role
        USING (true);
    END IF;
END $$;

-- ================================================
-- 4. FIX POTENTIAL Edge Function COMPATIBILITY
-- ================================================

-- Add activity_name as an alias/view for the 'name' column to fix Edge Function compatibility
-- This way both 'name' and 'activity_name' work
DO $$
BEGIN
    -- Check if we need to add activity_name column as alias
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'scheduled_activities' 
        AND column_name = 'activity_name'
    ) THEN
        -- Add activity_name as a computed column that mirrors 'name'
        ALTER TABLE public.scheduled_activities ADD COLUMN activity_name TEXT GENERATED ALWAYS AS (name) STORED;
        RAISE NOTICE 'Added activity_name computed column to scheduled_activities';
    END IF;
END $$;

-- ================================================
-- 5. VALIDATE FOREIGN KEY CONSTRAINTS
-- ================================================

-- Ensure user_preferences has proper foreign key to auth.users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_preferences' 
        AND constraint_name = 'user_preferences_user_id_fkey'
    ) THEN
        ALTER TABLE public.user_preferences
        ADD CONSTRAINT user_preferences_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint to user_preferences';
    END IF;
END $$;

-- ================================================
-- 6. REFRESH SCHEMA CACHE
-- ================================================

-- Refresh the PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- ================================================
-- 7. VERIFICATION QUERIES
-- ================================================

-- Verify all columns exist
SELECT 
    'user_preferences' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_preferences' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
    'scheduled_activities' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'scheduled_activities' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
    'places_cache' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'places_cache' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ================================================
-- MIGRATION COMPLETE
-- ================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Database schema migration completed successfully!';
    RAISE NOTICE '🔄 Please test your Flutter app onboarding flow now.';
    RAISE NOTICE '📊 Check the verification queries above to confirm all columns exist.';
END $$;
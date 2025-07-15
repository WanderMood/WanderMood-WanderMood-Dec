-- Fix Missing Tables and Relationships
-- Date: 2025-01-09
-- Purpose: Ensure all required tables exist and have proper relationships

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================
-- 1. SCHEDULED ACTIVITIES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.scheduled_activities (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
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
    payment_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id)
);

-- Add foreign key constraint to auth.users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scheduled_activities_user_id_fkey'
    ) THEN
        ALTER TABLE public.scheduled_activities
        ADD CONSTRAINT scheduled_activities_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Enable RLS and create policies
ALTER TABLE public.scheduled_activities ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own scheduled activities" ON public.scheduled_activities;
DROP POLICY IF EXISTS "Users can insert their own scheduled activities" ON public.scheduled_activities;
DROP POLICY IF EXISTS "Users can update their own scheduled activities" ON public.scheduled_activities;
DROP POLICY IF EXISTS "Users can delete their own scheduled activities" ON public.scheduled_activities;

-- Create RLS policies
CREATE POLICY "Users can view their own scheduled activities"
ON public.scheduled_activities FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own scheduled activities"
ON public.scheduled_activities FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own scheduled activities"
ON public.scheduled_activities FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own scheduled activities"
ON public.scheduled_activities FOR DELETE
USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS scheduled_activities_user_id_idx ON public.scheduled_activities(user_id);
CREATE INDEX IF NOT EXISTS scheduled_activities_start_time_idx ON public.scheduled_activities(start_time);

-- =============================================
-- 2. PROFILES TABLE (ENSURE IT EXISTS)
-- =============================================
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
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT true,
    language_preference TEXT DEFAULT 'en',
    theme_preference TEXT DEFAULT 'system',
    notification_preferences JSONB DEFAULT '{"push": true, "email": true, "travel_tips": true}',
    location_sharing BOOLEAN DEFAULT true,
    mood_sharing BOOLEAN DEFAULT true,
    mood_streak INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    achievements TEXT[] DEFAULT '{}',
    level INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop and recreate profile policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================
-- 3. DIARY ENTRIES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.diary_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    title TEXT,
    story TEXT NOT NULL,
    mood TEXT NOT NULL,
    location TEXT,
    location_coordinates GEOGRAPHY(POINT),
    tags TEXT[] DEFAULT '{}',
    photos TEXT[] DEFAULT '{}',
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for diary entries
ALTER TABLE public.diary_entries ENABLE ROW LEVEL SECURITY;

-- Drop and recreate diary policies
DROP POLICY IF EXISTS "Users can manage own diary entries" ON public.diary_entries;
DROP POLICY IF EXISTS "Users can view public diary entries" ON public.diary_entries;

CREATE POLICY "Users can manage own diary entries" 
ON public.diary_entries FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can view public diary entries" 
ON public.diary_entries FOR SELECT 
USING (is_public = true);

-- =============================================
-- 4. USER FOLLOWS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.user_follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID REFERENCES auth.users(id) NOT NULL,
    following_id UUID REFERENCES auth.users(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK(follower_id != following_id)
);

-- Enable RLS for user follows
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;

-- Drop and recreate follow policies
DROP POLICY IF EXISTS "Users can manage own follows" ON public.user_follows;
DROP POLICY IF EXISTS "Public read access for follows" ON public.user_follows;

CREATE POLICY "Users can manage own follows" 
ON public.user_follows FOR ALL 
USING (auth.uid() = follower_id);

CREATE POLICY "Public read access for follows" 
ON public.user_follows FOR SELECT 
USING (true);

-- =============================================
-- 5. STORAGE BUCKETS
-- =============================================

-- Create avatars bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create diary-photos bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('diary-photos', 'diary-photos', true)
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- 6. STORAGE POLICIES
-- =============================================

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Diary photos are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload diary photos" ON storage.objects;

-- Avatar storage policies
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own avatar" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Diary photos storage policies
CREATE POLICY "Diary photos are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'diary-photos');

CREATE POLICY "Users can upload diary photos" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'diary-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =============================================
-- 7. HELPER FUNCTIONS
-- =============================================

-- Function to ensure profile exists for user
CREATE OR REPLACE FUNCTION public.ensure_user_profile(user_uuid UUID)
RETURNS UUID AS $$
DECLARE
    profile_exists BOOLEAN;
    new_username TEXT;
BEGIN
    -- Check if profile exists
    SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id = user_uuid) INTO profile_exists;
    
    IF NOT profile_exists THEN
        -- Generate username
        new_username := 'wanderer_' || SUBSTRING(user_uuid::text FROM 1 FOR 8);
        
        -- Create profile
        INSERT INTO public.profiles (
            id,
            username,
            full_name,
            bio,
            currently_exploring
        ) VALUES (
            user_uuid,
            new_username,
            'WanderMood User',
            'Hello! I''m new to WanderMood 👋',
            'Rotterdam, Netherlands'
        );
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 8. CREATE INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles(username);
CREATE INDEX IF NOT EXISTS profiles_email_idx ON public.profiles(email);
CREATE INDEX IF NOT EXISTS diary_entries_user_id_idx ON public.diary_entries(user_id);
CREATE INDEX IF NOT EXISTS diary_entries_created_at_idx ON public.diary_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS user_follows_follower_idx ON public.user_follows(follower_id);
CREATE INDEX IF NOT EXISTS user_follows_following_idx ON public.user_follows(following_id); 
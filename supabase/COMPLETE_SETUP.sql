-- ============================================
-- WanderMood - Complete Database Setup
-- Run this entire script in your Supabase SQL Editor
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    email TEXT,
    bio TEXT,
    avatar_url TEXT,
    currently_exploring TEXT,
    travel_style TEXT DEFAULT 'adventurous',
    travel_vibes TEXT[] DEFAULT ARRAY['Spontaneous', 'Social', 'Relaxed'],
    favorite_mood TEXT DEFAULT 'happy',
    interests TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. USER_PREFERENCES TABLE
-- ============================================
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

-- Enable RLS
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can manage own preferences" ON public.user_preferences;
CREATE POLICY "Users can manage own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 3. SCHEDULED_ACTIVITIES TABLE
-- ============================================
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

-- Enable RLS
ALTER TABLE public.scheduled_activities ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own activities" ON public.scheduled_activities;
CREATE POLICY "Users can view own activities" ON public.scheduled_activities
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own activities" ON public.scheduled_activities;
CREATE POLICY "Users can insert own activities" ON public.scheduled_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own activities" ON public.scheduled_activities;
CREATE POLICY "Users can update own activities" ON public.scheduled_activities
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own activities" ON public.scheduled_activities;
CREATE POLICY "Users can delete own activities" ON public.scheduled_activities
    FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS scheduled_activities_user_id_idx ON public.scheduled_activities(user_id);
CREATE INDEX IF NOT EXISTS scheduled_activities_start_time_idx ON public.scheduled_activities(start_time);

-- ============================================
-- 4. MOODS TABLE
-- ============================================
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

-- Enable RLS
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can manage own moods" ON public.moods;
CREATE POLICY "Users can manage own moods" ON public.moods
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 5. ACTIVITIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT,
    description TEXT,
    mood_tags TEXT[],
    energy_level TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (public read, admin write)
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view activities" ON public.activities;
CREATE POLICY "Anyone can view activities" ON public.activities
    FOR SELECT USING (true);

-- ============================================
-- 6. USER_CHECK_INS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_check_ins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mood TEXT NOT NULL,
    text TEXT,
    activities_completed TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_check_ins ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can manage own check-ins" ON public.user_check_ins;
CREATE POLICY "Users can manage own check-ins" ON public.user_check_ins
    FOR ALL USING (auth.uid() = user_id);

-- Index for streak calculation
CREATE INDEX IF NOT EXISTS user_check_ins_user_created_idx ON public.user_check_ins(user_id, created_at);

-- ============================================
-- 7. ACTIVITY_RATINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.activity_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_id TEXT NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    tags TEXT[],
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id)
);

-- Enable RLS
ALTER TABLE public.activity_ratings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can manage own ratings" ON public.activity_ratings;
CREATE POLICY "Users can manage own ratings" ON public.activity_ratings
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 8. PLACES_CACHE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.cached_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    formatted_address TEXT,
    location JSONB NOT NULL,
    photos TEXT[],
    rating DOUBLE PRECISION,
    user_ratings_total INTEGER,
    types TEXT[],
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Enable RLS (public read)
ALTER TABLE public.cached_places ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view cached places" ON public.cached_places;
CREATE POLICY "Anyone can view cached places" ON public.cached_places
    FOR SELECT USING (true);

-- Index
CREATE INDEX IF NOT EXISTS cached_places_place_id_idx ON public.cached_places(place_id);
CREATE INDEX IF NOT EXISTS cached_places_expires_at_idx ON public.cached_places(expires_at);

-- ============================================
-- 9. USER_SAVED_PLACES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_saved_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    place_id TEXT NOT NULL,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, place_id)
);

-- Enable RLS
ALTER TABLE public.user_saved_places ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can manage own saved places" ON public.user_saved_places;
CREATE POLICY "Users can manage own saved places" ON public.user_saved_places
    FOR ALL USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS user_saved_places_user_id_idx ON public.user_saved_places(user_id);

-- ============================================
-- 10. WEATHER_CACHE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.weather_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location TEXT NOT NULL,
    weather_data JSONB NOT NULL,
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    UNIQUE(location)
);

-- Enable RLS (public read)
ALTER TABLE public.weather_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view weather cache" ON public.weather_cache;
CREATE POLICY "Anyone can view weather cache" ON public.weather_cache
    FOR SELECT USING (true);

-- ============================================
-- COMPLETE!
-- ============================================
-- All tables created with RLS policies
-- You can now use your new Supabase project with WanderMood!


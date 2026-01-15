-- ============================================
-- WanderMood - ROBUST Database Setup
-- Completely drops existing tables and recreates them properly
-- ============================================

-- First, let's completely drop ALL existing tables to start fresh
DROP TABLE IF EXISTS public.ai_recommendations CASCADE;
DROP TABLE IF EXISTS public.weather_cache CASCADE;
DROP TABLE IF EXISTS public.cached_places CASCADE;
DROP TABLE IF EXISTS public.activities CASCADE;
DROP TABLE IF EXISTS public.moods CASCADE;
DROP TABLE IF EXISTS public.user_preferences CASCADE;
DROP TABLE IF EXISTS public.scheduled_activities CASCADE;
DROP TABLE IF EXISTS public.mood_options CASCADE;
DROP TABLE IF EXISTS public.travel_recommendations CASCADE;
DROP TABLE IF EXISTS public.adventures CASCADE;
DROP TABLE IF EXISTS public.travel_mood_preferences CASCADE;

-- Keep profiles table but ensure it has the right structure
-- Note: We'll update this table rather than drop it to preserve user data

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. ENSURE PROFILES TABLE HAS RIGHT STRUCTURE
-- ============================================
-- Add any missing columns to existing profiles table
DO $$
BEGIN
    -- Add travel_style if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'travel_style') THEN
        ALTER TABLE public.profiles ADD COLUMN travel_style TEXT DEFAULT 'adventurous';
    END IF;
    
    -- Add travel_vibes if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'travel_vibes') THEN
        ALTER TABLE public.profiles ADD COLUMN travel_vibes TEXT[] DEFAULT ARRAY['Spontaneous', 'Social', 'Relaxed'];
    END IF;
    
    -- Add favorite_mood if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'favorite_mood') THEN
        ALTER TABLE public.profiles ADD COLUMN favorite_mood TEXT DEFAULT 'happy';
    END IF;
    
    -- Add currently_exploring if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'currently_exploring') THEN
        ALTER TABLE public.profiles ADD COLUMN currently_exploring TEXT;
    END IF;
    
    -- Add followers_count if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'followers_count') THEN
        ALTER TABLE public.profiles ADD COLUMN followers_count INTEGER DEFAULT 0;
    END IF;
    
    -- Add following_count if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'following_count') THEN
        ALTER TABLE public.profiles ADD COLUMN following_count INTEGER DEFAULT 0;
    END IF;
    
    -- Add posts_count if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'posts_count') THEN
        ALTER TABLE public.profiles ADD COLUMN posts_count INTEGER DEFAULT 0;
    END IF;
    
    -- Add is_public if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_public') THEN
        ALTER TABLE public.profiles ADD COLUMN is_public BOOLEAN DEFAULT true;
    END IF;
    
    -- Add location_sharing if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'location_sharing') THEN
        ALTER TABLE public.profiles ADD COLUMN location_sharing BOOLEAN DEFAULT true;
    END IF;
    
    -- Add mood_sharing if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'mood_sharing') THEN
        ALTER TABLE public.profiles ADD COLUMN mood_sharing BOOLEAN DEFAULT true;
    END IF;
    
    -- Add language_preference if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'language_preference') THEN
        ALTER TABLE public.profiles ADD COLUMN language_preference TEXT DEFAULT 'en';
    END IF;
    
    -- Add theme_preference if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'theme_preference') THEN
        ALTER TABLE public.profiles ADD COLUMN theme_preference TEXT DEFAULT 'system';
    END IF;
    
    -- Add notification_preferences if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'notification_preferences') THEN
        ALTER TABLE public.profiles ADD COLUMN notification_preferences JSONB DEFAULT '{"push": true, "email": true, "travel_tips": true}';
    END IF;
    
    -- Add mood_streak if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'mood_streak') THEN
        ALTER TABLE public.profiles ADD COLUMN mood_streak INTEGER DEFAULT 0;
    END IF;
    
    -- Add total_points if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_points') THEN
        ALTER TABLE public.profiles ADD COLUMN total_points INTEGER DEFAULT 0;
    END IF;
    
    -- Add achievements if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'achievements') THEN
        ALTER TABLE public.profiles ADD COLUMN achievements TEXT[] DEFAULT ARRAY[]::TEXT[];
    END IF;
    
    -- Add level if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'level') THEN
        ALTER TABLE public.profiles ADD COLUMN level INTEGER DEFAULT 1;
    END IF;
    
    -- Add last_active_at if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_active_at') THEN
        ALTER TABLE public.profiles ADD COLUMN last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- ============================================
-- 2. USER PREFERENCES (Fresh table)
-- ============================================
CREATE TABLE public.user_preferences (
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

-- ============================================
-- 3. MOODS (Fresh table)
-- ============================================
CREATE TABLE public.moods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Mood data
    mood TEXT NOT NULL,
    activity TEXT,
    energy_level NUMERIC CHECK (energy_level >= 1 AND energy_level <= 10),
    notes TEXT,
    
    -- Context
    location TEXT,
    weather_condition TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. ACTIVITIES (Fresh table)
-- ============================================
CREATE TABLE public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    mood_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    weather_suitability TEXT[] DEFAULT ARRAY[]::TEXT[],
    energy_level_required INTEGER DEFAULT 5,
    indoor_outdoor TEXT DEFAULT 'both',
    duration_minutes INTEGER,
    image_url TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 5. CACHED PLACES (Fresh table)
-- ============================================
CREATE TABLE public.cached_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    
    -- Location data
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    city TEXT,
    country TEXT,
    
    -- Place metadata
    place_type TEXT NOT NULL,
    categories TEXT[] DEFAULT ARRAY[]::TEXT[],
    rating DOUBLE PRECISION,
    price_level INTEGER,
    
    -- Mood & weather suitability
    mood_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    weather_suitability TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Additional data
    image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    opening_hours JSONB,
    website TEXT,
    phone TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 6. AI RECOMMENDATIONS (Fresh table)
-- ============================================
CREATE TABLE public.ai_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Context
    location TEXT NOT NULL,
    mood TEXT NOT NULL,
    weather_condition TEXT,
    
    -- Recommendation data
    recommendations JSONB NOT NULL,
    confidence_score DOUBLE PRECISION DEFAULT 0.0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

-- ============================================
-- 7. WEATHER CACHE (Fresh table)
-- ============================================
CREATE TABLE public.weather_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    
    -- Weather data
    current_weather JSONB NOT NULL,
    forecast JSONB,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '1 hour')
);

-- ============================================
-- INDEXES for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_moods_user_id_created_at ON public.moods(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_category ON public.activities(category);
CREATE INDEX IF NOT EXISTS idx_activities_mood_tags ON public.activities USING GIN(mood_tags);
CREATE INDEX IF NOT EXISTS idx_cached_places_location ON public.cached_places(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_cached_places_place_type ON public.cached_places(place_type);
CREATE INDEX IF NOT EXISTS idx_cached_places_mood_tags ON public.cached_places USING GIN(mood_tags);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user_id ON public.ai_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_weather_cache_location ON public.weather_cache(location, expires_at);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cached_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weather_cache ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view public profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can manage their own moods" ON public.moods;
DROP POLICY IF EXISTS "Anyone can view activities" ON public.activities;
DROP POLICY IF EXISTS "Anyone can view cached places" ON public.cached_places;
DROP POLICY IF EXISTS "Users can manage their own AI recommendations" ON public.ai_recommendations;
DROP POLICY IF EXISTS "Anyone can view weather cache" ON public.weather_cache;

-- Create fresh policies
CREATE POLICY "Users can view public profiles" ON public.profiles
    FOR SELECT USING (is_public = true OR auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can manage their own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own moods" ON public.moods
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view activities" ON public.activities
    FOR SELECT TO public;

CREATE POLICY "Anyone can view cached places" ON public.cached_places
    FOR SELECT TO public;

CREATE POLICY "Users can manage their own AI recommendations" ON public.ai_recommendations
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view weather cache" ON public.weather_cache
    FOR SELECT TO public;

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON public.user_preferences;
DROP TRIGGER IF EXISTS update_activities_updated_at ON public.activities;
DROP TRIGGER IF EXISTS update_cached_places_updated_at ON public.cached_places;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON public.activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cached_places_updated_at BEFORE UPDATE ON public.cached_places
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Insert sample activities
INSERT INTO public.activities (name, description, category, mood_tags, weather_suitability, indoor_outdoor, duration_minutes) VALUES
('Visit a Museum', 'Explore art, history, and culture', 'Cultural', ARRAY['contemplative', 'cultural', 'relaxed'], ARRAY['rainy', 'cloudy', 'cold'], 'indoor', 120),
('Go Hiking', 'Explore nature trails and scenic views', 'Adventure', ARRAY['adventurous', 'energetic'], ARRAY['sunny', 'cloudy'], 'outdoor', 180),
('Cafe Hopping', 'Discover local coffee culture', 'Social', ARRAY['social', 'relaxed'], ARRAY['rainy', 'cloudy', 'cold'], 'indoor', 90),
('Beach Walk', 'Relaxing stroll along the shoreline', 'Relaxation', ARRAY['relaxed', 'romantic'], ARRAY['sunny', 'hot'], 'outdoor', 60),
('Art Gallery', 'Contemporary and classic art viewing', 'Cultural', ARRAY['contemplative', 'cultural', 'creative'], ARRAY['rainy', 'cloudy'], 'indoor', 90),
('Food Market', 'Explore local cuisine and flavors', 'Culinary', ARRAY['social', 'adventurous'], ARRAY['sunny', 'cloudy'], 'outdoor', 120),
('Spa Day', 'Relaxation and wellness treatments', 'Wellness', ARRAY['relaxed', 'romantic'], ARRAY['rainy', 'cloudy', 'cold'], 'indoor', 240),
('City Tour', 'Guided exploration of city highlights', 'Cultural', ARRAY['cultural', 'social'], ARRAY['sunny', 'cloudy'], 'outdoor', 180);

-- Success message
SELECT '🎉 WanderMood database successfully created with robust error handling!' as status; 
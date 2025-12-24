-- ============================================
-- WanderMood - FIXED Database Setup
-- Includes mood_options table that the app needs
-- ============================================

-- First, let's completely drop ALL existing tables to start fresh
DROP TABLE IF EXISTS public.ai_recommendations CASCADE;
DROP TABLE IF EXISTS public.weather_cache CASCADE;
DROP TABLE IF EXISTS public.cached_places CASCADE;
DROP TABLE IF EXISTS public.activities CASCADE;
DROP TABLE IF EXISTS public.mood_options CASCADE;
DROP TABLE IF EXISTS public.moods CASCADE;
DROP TABLE IF EXISTS public.user_preferences CASCADE;
DROP TABLE IF EXISTS public.scheduled_activities CASCADE;
DROP TABLE IF EXISTS public.travel_recommendations CASCADE;
DROP TABLE IF EXISTS public.adventures CASCADE;
DROP TABLE IF EXISTS public.travel_mood_preferences CASCADE;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. MOOD OPTIONS (What the app is looking for!)
-- ============================================
CREATE TABLE public.mood_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    emoji TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. USER PREFERENCES (App settings)
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
-- 3. MOODS (Mood tracking)
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
-- 4. ACTIVITIES (Available activities)
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
-- 5. CACHED PLACES (Venue data)
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
-- 6. AI RECOMMENDATIONS (AI suggestions)
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
-- 7. WEATHER CACHE (Weather data)
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
CREATE INDEX IF NOT EXISTS idx_mood_options_display_order ON public.mood_options(display_order);
CREATE INDEX IF NOT EXISTS idx_mood_options_active ON public.mood_options(is_active);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_moods_user_id_created_at ON public.moods(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_category ON public.activities(category);
CREATE INDEX IF NOT EXISTS idx_activities_mood_tags ON public.activities USING GIN(mood_tags);
CREATE INDEX IF NOT EXISTS idx_cached_places_location ON public.cached_places(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_cached_places_mood_tags ON public.cached_places USING GIN(mood_tags);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user_id ON public.ai_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_weather_cache_location ON public.weather_cache(location, expires_at);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.mood_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cached_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weather_cache ENABLE ROW LEVEL SECURITY;

-- Mood options policies (public read)
CREATE POLICY "Anyone can view mood options" ON public.mood_options
    FOR SELECT TO public;

-- User preferences policies
CREATE POLICY "Users can manage their own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Moods policies
CREATE POLICY "Users can manage their own moods" ON public.moods
    FOR ALL USING (auth.uid() = user_id);

-- Activities policies (public read)
CREATE POLICY "Anyone can view activities" ON public.activities
    FOR SELECT TO public;

-- Cached places policies (public read)
CREATE POLICY "Anyone can view cached places" ON public.cached_places
    FOR SELECT TO public;

-- AI recommendations policies
CREATE POLICY "Users can manage their own AI recommendations" ON public.ai_recommendations
    FOR ALL USING (auth.uid() = user_id);

-- Weather cache policies (public read)
CREATE POLICY "Anyone can view weather cache" ON public.weather_cache
    FOR SELECT TO public;

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Insert mood options that the app needs
INSERT INTO public.mood_options (name, emoji, description, color, display_order, is_active) VALUES
('Happy', '😊', 'Feeling joyful and positive', '#FFD700', 1, true),
('Adventurous', '🚀', 'Ready for excitement and exploration', '#FF6B6B', 2, true),
('Relaxed', '😌', 'Calm and peaceful state of mind', '#4ECDC4', 3, true),
('Energetic', '⚡', 'Full of energy and enthusiasm', '#45B7D1', 4, true),
('Contemplative', '🤔', 'Thoughtful and introspective', '#96CEB4', 5, true),
('Social', '👥', 'Want to connect with others', '#FFEAA7', 6, true),
('Romantic', '💕', 'In the mood for romance', '#FD79A8', 7, true),
('Cultural', '🎭', 'Interested in arts and culture', '#A29BFE', 8, true),
('Curious', '🔍', 'Eager to learn and discover', '#FF7675', 9, true),
('Peaceful', '🕊️', 'Seeking tranquility and serenity', '#81ECEC', 10, true);

-- Insert sample activities
INSERT INTO public.activities (name, description, category, mood_tags, weather_suitability, indoor_outdoor, duration_minutes) VALUES
('Visit a Museum', 'Explore art, history, and culture', 'Cultural', ARRAY['contemplative', 'cultural', 'relaxed'], ARRAY['rainy', 'cloudy', 'cold'], 'indoor', 120),
('Go Hiking', 'Explore nature trails and scenic views', 'Adventure', ARRAY['adventurous', 'energetic'], ARRAY['sunny', 'cloudy'], 'outdoor', 180),
('Cafe Hopping', 'Discover local coffee culture', 'Social', ARRAY['social', 'relaxed'], ARRAY['rainy', 'cloudy', 'cold'], 'indoor', 90),
('Beach Walk', 'Relaxing stroll along the shoreline', 'Relaxation', ARRAY['relaxed', 'romantic'], ARRAY['sunny', 'hot'], 'outdoor', 60),
('Art Gallery', 'Contemporary and classic art viewing', 'Cultural', ARRAY['contemplative', 'cultural', 'curious'], ARRAY['rainy', 'cloudy'], 'indoor', 90),
('Food Market', 'Explore local cuisine and flavors', 'Culinary', ARRAY['social', 'adventurous'], ARRAY['sunny', 'cloudy'], 'outdoor', 120),
('Spa Day', 'Relaxation and wellness treatments', 'Wellness', ARRAY['relaxed', 'peaceful'], ARRAY['rainy', 'cloudy', 'cold'], 'indoor', 240),
('City Tour', 'Guided exploration of city highlights', 'Cultural', ARRAY['cultural', 'social', 'curious'], ARRAY['sunny', 'cloudy'], 'outdoor', 180);

-- Success message
SELECT '🎉 WanderMood database fixed! Mood options table created successfully!' as status; 
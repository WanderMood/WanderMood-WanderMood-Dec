-- ============================================
-- WanderMood - Clean Database Setup
-- Only Essential Tables for Personalized Travel AI
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- 1. USER PROFILES (Core user data)
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    
    -- Travel preferences
    travel_style TEXT DEFAULT 'adventurous',
    travel_vibes TEXT[] DEFAULT ARRAY['Spontaneous', 'Social', 'Relaxed'],
    favorite_mood TEXT DEFAULT 'happy',
    currently_exploring TEXT,
    
    -- Social stats
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    
    -- Privacy settings
    is_public BOOLEAN DEFAULT true,
    location_sharing BOOLEAN DEFAULT true,
    mood_sharing BOOLEAN DEFAULT true,
    
    -- Preferences
    language_preference TEXT DEFAULT 'en',
    theme_preference TEXT DEFAULT 'system',
    notification_preferences JSONB DEFAULT '{"push": true, "email": true, "travel_tips": true}',
    
    -- Gamification
    mood_streak INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    achievements TEXT[] DEFAULT ARRAY[]::TEXT[],
    level INTEGER DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. USER PREFERENCES (App settings for personalization)
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

-- ============================================
-- 3. MOODS (Mood tracking for personalization)
-- ============================================
CREATE TABLE IF NOT EXISTS public.moods (
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
-- 4. ACTIVITIES (Available activities for recommendations)
-- ============================================
CREATE TABLE IF NOT EXISTS public.activities (
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
-- 5. CACHED PLACES (Venue data for recommendations)
-- ============================================
CREATE TABLE IF NOT EXISTS public.cached_places (
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
-- 6. AI RECOMMENDATIONS (AI-generated travel suggestions)
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_recommendations (
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
-- 7. WEATHER CACHE (Weather data caching)
-- ============================================
CREATE TABLE IF NOT EXISTS public.weather_cache (
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

-- Profiles policies
CREATE POLICY "Users can view public profiles" ON public.profiles
    FOR SELECT USING (is_public = true OR auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- User preferences policies
CREATE POLICY "Users can manage their own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Moods policies
CREATE POLICY "Users can manage their own moods" ON public.moods
    FOR ALL USING (auth.uid() = user_id);

-- Activities policies (public read, admin write)
CREATE POLICY "Anyone can view activities" ON public.activities
    FOR SELECT TO public;

-- Cached places policies (public read, admin write)
CREATE POLICY "Anyone can view cached places" ON public.cached_places
    FOR SELECT TO public;

-- AI recommendations policies
CREATE POLICY "Users can manage their own AI recommendations" ON public.ai_recommendations
    FOR ALL USING (auth.uid() = user_id);

-- Weather cache policies (public read, admin write)
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
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON public.activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cached_places_updated_at BEFORE UPDATE ON public.cached_places
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- CLEANUP OLD DATA
-- ============================================

-- Clean up expired AI recommendations
CREATE OR REPLACE FUNCTION cleanup_expired_recommendations()
RETURNS void AS $$
BEGIN
    DELETE FROM public.ai_recommendations WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Clean up expired weather cache
CREATE OR REPLACE FUNCTION cleanup_expired_weather_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM public.weather_cache WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SAMPLE DATA (Optional)
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
SELECT 'WanderMood database successfully created with essential tables only!' as status; 
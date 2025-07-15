-- WanderMood AI Database Schema
-- This migration creates tables needed for the AI Edge Function

-- Table for user preferences and settings
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    budget_range integer DEFAULT 100,
    preferred_time_slots text[] DEFAULT array['morning', 'afternoon', 'evening'],
    favorite_moods text[] DEFAULT array[]::text[],
    dietary_restrictions text[] DEFAULT array[]::text[],
    mobility_requirements text[] DEFAULT array[]::text[],
    language_preference text DEFAULT 'en',
    notification_preferences jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for user activity history
CREATE TABLE IF NOT EXISTS public.user_activity_history (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_id text NOT NULL,
    name text NOT NULL,
    mood text NOT NULL,
    location_lat double precision,
    location_lng double precision,
    rating double precision,
    feedback_rating integer, -- User's rating 1-5
    feedback_notes text,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for AI conversation history
CREATE TABLE IF NOT EXISTS public.ai_conversations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id text NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content text NOT NULL,
    metadata jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for cached places (enhanced from existing)
CREATE TABLE IF NOT EXISTS public.cached_places (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    place_id text UNIQUE NOT NULL,
    name text NOT NULL,
    rating double precision,
    user_ratings_total integer,
    types text[] DEFAULT array[]::text[],
    location_lat double precision NOT NULL,
    location_lng double precision NOT NULL,
    address text,
    phone_number text,
    website text,
    opening_hours jsonb,
    price_level integer,
    photos text[] DEFAULT array[]::text[],
    moods text[] DEFAULT array[]::text[], -- Associated moods
    description text,
    ai_insights jsonb DEFAULT '{}', -- AI-generated insights about the place
    last_verified timestamp with time zone DEFAULT timezone('utc'::text, now()),
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for AI recommendations tracking
CREATE TABLE IF NOT EXISTS public.ai_recommendations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    recommendation_type text NOT NULL, -- 'activity', 'restaurant', 'plan', etc.
    input_moods text[] NOT NULL,
    input_location jsonb NOT NULL,
    recommendations jsonb NOT NULL,
    user_feedback integer, -- 1-5 rating
    user_selected text[], -- Which recommendations user selected
    context_used jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_history_user_id ON public.user_activity_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_history_mood ON public.user_activity_history(mood);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_conversation_id ON public.ai_conversations(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id ON public.ai_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_cached_places_location ON public.cached_places(location_lat, location_lng);
CREATE INDEX IF NOT EXISTS idx_cached_places_moods ON public.cached_places USING GIN(moods);
CREATE INDEX IF NOT EXISTS idx_cached_places_rating ON public.cached_places(rating);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user_id ON public.ai_recommendations(user_id);

-- Row Level Security (RLS) policies
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cached_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_preferences
CREATE POLICY "Users can view their own preferences" ON public.user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own preferences" ON public.user_preferences FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own preferences" ON public.user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for user_activity_history
CREATE POLICY "Users can view their own activity history" ON public.user_activity_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own activity history" ON public.user_activity_history FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own activity history" ON public.user_activity_history FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for ai_conversations
CREATE POLICY "Users can view their own conversations" ON public.ai_conversations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own conversations" ON public.ai_conversations FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for cached_places (public read, service role write)
CREATE POLICY "Anyone can view cached places" ON public.cached_places FOR SELECT TO public USING (true);
CREATE POLICY "Service role can manage cached places" ON public.cached_places FOR ALL TO service_role USING (true);

-- RLS Policies for ai_recommendations
CREATE POLICY "Users can view their own recommendations" ON public.ai_recommendations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own recommendations" ON public.ai_recommendations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own recommendations" ON public.ai_recommendations FOR UPDATE USING (auth.uid() = user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language plpgsql;

-- Add updated_at triggers
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.cached_places FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at(); 
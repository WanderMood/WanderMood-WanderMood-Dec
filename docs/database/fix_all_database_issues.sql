-- Comprehensive Database Fix for WanderMood
-- This SQL script fixes all reported database issues

-- 1. Fix profiles table - Add missing achievements column
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS achievements jsonb DEFAULT '[]'::jsonb;

-- Add any other missing profile columns that might be expected
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS mood_streak integer DEFAULT 0;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS followers_count integer DEFAULT 0;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS following_count integer DEFAULT 0;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_public boolean DEFAULT true;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS notification_preferences jsonb DEFAULT '{"push": true, "email": true}'::jsonb;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS theme_preference varchar(20) DEFAULT 'system';
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS language_preference varchar(10) DEFAULT 'en';
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS favorite_mood varchar(50);
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS total_points integer DEFAULT 0;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS level integer DEFAULT 1;

-- 2. Create mood_options table for mood selection screen
CREATE TABLE IF NOT EXISTS public.mood_options (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    label varchar(50) NOT NULL UNIQUE,
    emoji varchar(10) NOT NULL,
    description text,
    color_hex varchar(7) DEFAULT '#6366f1',
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Insert default mood options (same as the hardcoded ones in the app)
INSERT INTO public.mood_options (label, emoji, description, color_hex, display_order) VALUES
('Adventurous', '🏔️', 'Ready for thrilling experiences', '#ef4444', 1),
('Relaxed', '🧘', 'Peaceful and calm activities', '#10b981', 2),
('Foody', '🍕', 'Culinary adventures await', '#f59e0b', 3),
('Cultural', '🎭', 'Arts, museums, and heritage', '#8b5cf6', 4),
('Romantic', '💕', 'Perfect for couples', '#ec4899', 5),
('Social', '👥', 'Great for meeting people', '#3b82f6', 6),
('Active', '🏃', 'Sports and fitness focused', '#059669', 7),
('Mindful', '🕯️', 'Meditation and wellness', '#7c3aed', 8),
('Creative', '🎨', 'Art and creative expression', '#dc2626', 9),
('Spontaneous', '🎲', 'Surprise me with anything', '#65a30d', 10)
ON CONFLICT (label) DO UPDATE SET
    emoji = EXCLUDED.emoji,
    description = EXCLUDED.description,
    color_hex = EXCLUDED.color_hex,
    display_order = EXCLUDED.display_order,
    updated_at = timezone('utc'::text, now());

-- 4. Create any missing tables for chat functionality
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    message text NOT NULL,
    response text,
    is_from_user boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Update profiles table trigger for updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to profiles table
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Apply trigger to mood_options table
DROP TRIGGER IF EXISTS update_mood_options_updated_at ON public.mood_options;
CREATE TRIGGER update_mood_options_updated_at
    BEFORE UPDATE ON public.mood_options
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 6. Set up proper RLS policies for mood_options
ALTER TABLE public.mood_options ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read mood options (they're public)
CREATE POLICY "Anyone can view mood options" ON public.mood_options
    FOR SELECT USING (true);

-- Only authenticated users can suggest new moods (admin feature)
CREATE POLICY "Authenticated users can suggest moods" ON public.mood_options
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 7. Set up RLS policies for chat_messages
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can view their own chat messages
CREATE POLICY "Users can view their own chat messages" ON public.chat_messages
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own chat messages
CREATE POLICY "Users can insert their own chat messages" ON public.chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 8. Fix any existing profile records to have default values
UPDATE public.profiles SET 
    achievements = COALESCE(achievements, '[]'::jsonb),
    mood_streak = COALESCE(mood_streak, 0),
    followers_count = COALESCE(followers_count, 0),
    following_count = COALESCE(following_count, 0),
    is_public = COALESCE(is_public, true),
    notification_preferences = COALESCE(notification_preferences, '{"push": true, "email": true}'::jsonb),
    theme_preference = COALESCE(theme_preference, 'system'),
    language_preference = COALESCE(language_preference, 'en'),
    total_points = COALESCE(total_points, 0),
    level = COALESCE(level, 1),
    updated_at = timezone('utc'::text, now())
WHERE achievements IS NULL 
   OR mood_streak IS NULL 
   OR followers_count IS NULL 
   OR following_count IS NULL 
   OR is_public IS NULL 
   OR notification_preferences IS NULL 
   OR theme_preference IS NULL 
   OR language_preference IS NULL 
   OR total_points IS NULL 
   OR level IS NULL;

-- 9. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_mood_options_active_order ON public.mood_options (is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_created ON public.chat_messages (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON public.profiles (updated_at DESC);

-- 10. Grant necessary permissions
GRANT SELECT ON public.mood_options TO anon, authenticated;
GRANT ALL ON public.chat_messages TO authenticated;

-- End of comprehensive database fix
-- Run this script in Supabase SQL Editor to fix all database-related issues 
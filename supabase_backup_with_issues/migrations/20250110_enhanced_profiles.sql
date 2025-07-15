-- Enhanced profiles table for WanderMood
-- Drop existing table if needed (be careful in production!)
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Create comprehensive profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic user info
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    email TEXT,
    bio TEXT,
    avatar_url TEXT,
    
    -- Travel-specific fields
    currently_exploring TEXT,
    travel_style TEXT DEFAULT 'adventurous',
    travel_vibes TEXT[] DEFAULT '{"Spontaneous", "Social", "Relaxed"}',
    favorite_mood TEXT DEFAULT 'happy',
    
    -- Social stats
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    
    -- Preferences
    is_public BOOLEAN DEFAULT true,
    language_preference TEXT DEFAULT 'en',
    theme_preference TEXT DEFAULT 'system',
    notification_preferences JSONB DEFAULT '{"push": true, "email": true, "travel_tips": true}',
    
    -- Privacy & settings
    location_sharing BOOLEAN DEFAULT true,
    mood_sharing BOOLEAN DEFAULT true,
    
    -- Gamification
    mood_streak INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    achievements TEXT[] DEFAULT '{}',
    level INTEGER DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Function to generate unique username
CREATE OR REPLACE FUNCTION generate_unique_username(base_name TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
    username TEXT;
    counter INTEGER := 0;
BEGIN
    -- Use provided name or generate from email/id
    IF base_name IS NULL THEN
        base_name := 'wanderer';
    END IF;
    
    -- Clean the base name (remove spaces, special chars)
    base_name := LOWER(REGEXP_REPLACE(base_name, '[^a-zA-Z0-9]', '', 'g'));
    base_name := SUBSTRING(base_name FROM 1 FOR 15); -- Limit length
    
    -- Try base name first
    username := base_name;
    
    -- If taken, add numbers until unique
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE profiles.username = username) LOOP
        counter := counter + 1;
        username := base_name || counter::TEXT;
    END LOOP;
    
    RETURN username;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_username TEXT;
    display_name TEXT;
BEGIN
    -- Extract name from metadata or email
    display_name := COALESCE(
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'full_name',
        SPLIT_PART(NEW.email, '@', 1)
    );
    
    -- Generate unique username
    new_username := generate_unique_username(display_name);
    
    -- Create profile
    INSERT INTO public.profiles (
        id,
        username,
        full_name,
        email,
        bio,
        currently_exploring,
        created_at,
        updated_at,
        last_active_at
    ) VALUES (
        NEW.id,
        new_username,
        display_name,
        NEW.email,
        'Hello! I''m new to WanderMood 👋',
        'Rotterdam, Netherlands', -- Default location
        NOW(),
        NOW(),
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for auto-creating profiles
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update last_active_at
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.last_active_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update timestamps
CREATE TRIGGER update_profile_timestamps
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_last_active();

-- Indexes for performance
CREATE INDEX profiles_username_idx ON public.profiles(username);
CREATE INDEX profiles_email_idx ON public.profiles(email);
CREATE INDEX profiles_is_public_idx ON public.profiles(is_public);
CREATE INDEX profiles_created_at_idx ON public.profiles(created_at);
CREATE INDEX profiles_travel_style_idx ON public.profiles(travel_style);

-- Storage bucket for profile images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
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
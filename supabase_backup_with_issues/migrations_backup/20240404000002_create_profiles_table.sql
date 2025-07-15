-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users(id) PRIMARY KEY,
    email text NOT NULL,
    username text UNIQUE,
    full_name text,
    image_url text,
    date_of_birth date,
    bio text,
    favorite_mood text,
    mood_streak integer DEFAULT 0,
    followers_count integer DEFAULT 0,
    following_count integer DEFAULT 0,
    is_public boolean DEFAULT true,
    notification_preferences jsonb DEFAULT '{"push": true, "email": true}'::jsonb,
    theme_preference text DEFAULT 'system',
    language_preference text DEFAULT 'en',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Add achievements column if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'achievements'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN achievements jsonb DEFAULT '[]'::jsonb;
    END IF;
END $$;

-- Create index for username searches
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles (username);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Create policies
CREATE POLICY "Users can view their own profile" 
    ON public.profiles 
    FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
    ON public.profiles 
    FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Public profiles are viewable by everyone" 
    ON public.profiles 
    FOR SELECT 
    USING (is_public = true OR auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Create or replace the function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;

-- Create trigger for updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create or replace the function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        email, 
        username,
        full_name,
        bio,
        mood_streak,
        followers_count,
        following_count,
        is_public,
        notification_preferences,
        theme_preference,
        language_preference,
        created_at, 
        updated_at
    )
    VALUES (
        new.id, 
        new.email,
        'user_' || substr(new.id::text, 1, 8),
        COALESCE(new.raw_user_meta_data->>'full_name', 'New User'),
        'Hello! I''m new to WanderMood 👋',
        0,
        0,
        0,
        true,
        '{"push": true, "email": true}'::jsonb,
        'system',
        'en',
        now(), 
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(profiles.full_name, EXCLUDED.full_name),
        username = COALESCE(profiles.username, EXCLUDED.username),
        bio = COALESCE(profiles.bio, EXCLUDED.bio),
        updated_at = now()
    WHERE profiles.id = EXCLUDED.id;
    RETURN new;
END;
$$ language plpgsql security definer;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user(); 
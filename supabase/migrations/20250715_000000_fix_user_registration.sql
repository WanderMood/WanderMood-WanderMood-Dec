-- Fix User Registration Issues
-- Date: 2025-07-14
-- Purpose: Fix automatic profile creation when users register

-- =============================================
-- 1. CREATE TRIGGER FUNCTION FOR USER REGISTRATION
-- =============================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_username TEXT;
BEGIN
    -- Generate a unique username
    new_username := 'wanderer_' || SUBSTRING(NEW.id::text FROM 1 FOR 8);
    
    -- Ensure username is unique
    WHILE EXISTS(SELECT 1 FROM public.profiles WHERE username = new_username) LOOP
        new_username := 'wanderer_' || SUBSTRING(NEW.id::text FROM 1 FOR 8) || '_' || floor(random() * 1000)::text;
    END LOOP;
    
    -- Create profile for new user
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
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'WanderMood User'),
        NEW.email,
        'Hello! I''m new to WanderMood 👋',
        'Rotterdam, Netherlands',
        NOW(),
        NOW(),
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't prevent user creation
        RAISE NOTICE 'Error creating profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 2. CREATE TRIGGER FOR AUTOMATIC PROFILE CREATION
-- =============================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- 3. ENSURE EXISTING USERS HAVE PROFILES
-- =============================================

-- Create profiles for any existing users who don't have them
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
)
SELECT 
    u.id,
    'wanderer_' || SUBSTRING(u.id::text FROM 1 FOR 8) || '_' || ROW_NUMBER() OVER(),
    COALESCE(u.raw_user_meta_data->>'full_name', 'WanderMood User'),
    u.email,
    'Hello! I''m new to WanderMood 👋',
    'Rotterdam, Netherlands',
    u.created_at,
    NOW(),
    NOW()
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- =============================================
-- 4. FIX SCHEDULED ACTIVITIES TABLE REFERENCE
-- =============================================

-- Ensure the scheduled_activities table exists with proper foreign key
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
    payment_type TEXT DEFAULT 'free',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id)
);

-- Add foreign key constraint if it doesn't exist
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

-- Enable RLS and create policies for scheduled_activities
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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS scheduled_activities_user_id_idx ON public.scheduled_activities(user_id);
CREATE INDEX IF NOT EXISTS scheduled_activities_start_time_idx ON public.scheduled_activities(start_time);

-- =============================================
-- 5. VERIFY PROFILE FOREIGN KEY CONSTRAINT
-- =============================================

-- Ensure profiles table has proper foreign key to auth.users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'profiles_id_fkey'
    ) THEN
        ALTER TABLE public.profiles
        ADD CONSTRAINT profiles_id_fkey
        FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated; 
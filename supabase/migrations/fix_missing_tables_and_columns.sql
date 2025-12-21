-- ============================================
-- Fix Missing Tables and Columns
-- Run this in Supabase SQL Editor to fix all database errors
-- ============================================

-- ============================================
-- 1. FIX user_check_ins TABLE
-- ============================================
-- Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add 'timestamp' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_check_ins' 
        AND column_name = 'timestamp'
    ) THEN
        ALTER TABLE public.user_check_ins 
        ADD COLUMN timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add 'activities' column if it doesn't exist (rename from activities_completed if needed)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_check_ins' 
        AND column_name = 'activities'
    ) THEN
        -- Check if activities_completed exists, rename it
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_check_ins' 
            AND column_name = 'activities_completed'
        ) THEN
            ALTER TABLE public.user_check_ins 
            RENAME COLUMN activities_completed TO activities;
        ELSE
            ALTER TABLE public.user_check_ins 
            ADD COLUMN activities TEXT[] DEFAULT '{}';
        END IF;
    END IF;

    -- Add 'reactions' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_check_ins' 
        AND column_name = 'reactions'
    ) THEN
        ALTER TABLE public.user_check_ins 
        ADD COLUMN reactions TEXT[] DEFAULT '{}';
    END IF;

    -- Add 'metadata' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_check_ins' 
        AND column_name = 'metadata'
    ) THEN
        ALTER TABLE public.user_check_ins 
        ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;
END $$;

-- ============================================
-- 2. FIX activity_ratings TABLE
-- ============================================
-- Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add 'stars' column if it doesn't exist (rename from rating if needed)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'activity_ratings' 
        AND column_name = 'stars'
    ) THEN
        -- Check if rating exists, rename it
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'activity_ratings' 
            AND column_name = 'rating'
        ) THEN
            ALTER TABLE public.activity_ratings 
            RENAME COLUMN rating TO stars;
        ELSE
            ALTER TABLE public.activity_ratings 
            ADD COLUMN stars INTEGER CHECK (stars >= 1 AND stars <= 5);
        END IF;
    END IF;

    -- Add 'completed_at' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'activity_ratings' 
        AND column_name = 'completed_at'
    ) THEN
        ALTER TABLE public.activity_ratings 
        ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add 'activity_name' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'activity_ratings' 
        AND column_name = 'activity_name'
    ) THEN
        ALTER TABLE public.activity_ratings 
        ADD COLUMN activity_name TEXT;
    END IF;

    -- Add 'place_name' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'activity_ratings' 
        AND column_name = 'place_name'
    ) THEN
        ALTER TABLE public.activity_ratings 
        ADD COLUMN place_name TEXT;
    END IF;

    -- Add 'would_recommend' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'activity_ratings' 
        AND column_name = 'would_recommend'
    ) THEN
        ALTER TABLE public.activity_ratings 
        ADD COLUMN would_recommend BOOLEAN DEFAULT false;
    END IF;

    -- Add 'mood' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'activity_ratings' 
        AND column_name = 'mood'
    ) THEN
        ALTER TABLE public.activity_ratings 
        ADD COLUMN mood TEXT;
    END IF;
END $$;

-- ============================================
-- 3. CREATE ai_conversations TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own conversations" ON public.ai_conversations;
CREATE POLICY "Users can view own conversations" ON public.ai_conversations
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own conversations" ON public.ai_conversations;
CREATE POLICY "Users can insert own conversations" ON public.ai_conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS ai_conversations_conversation_id_idx ON public.ai_conversations(conversation_id);
CREATE INDEX IF NOT EXISTS ai_conversations_user_id_idx ON public.ai_conversations(user_id);
CREATE INDEX IF NOT EXISTS ai_conversations_created_at_idx ON public.ai_conversations(created_at);

-- ============================================
-- 4. CREATE places_cache TABLE (if it doesn't exist)
-- ============================================
CREATE TABLE IF NOT EXISTS public.places_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT UNIQUE NOT NULL,
    data JSONB NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    request_type TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (public read)
ALTER TABLE public.places_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view places cache" ON public.places_cache;
CREATE POLICY "Anyone can view places cache" ON public.places_cache
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert places cache" ON public.places_cache;
CREATE POLICY "Users can insert places cache" ON public.places_cache
    FOR INSERT WITH CHECK (true);

-- Indexes
CREATE INDEX IF NOT EXISTS places_cache_cache_key_idx ON public.places_cache(cache_key);
CREATE INDEX IF NOT EXISTS places_cache_expires_at_idx ON public.places_cache(expires_at);

-- ============================================
-- 5. CREATE place_reviews_cache TABLE (for reviews caching)
-- ============================================
CREATE TABLE IF NOT EXISTS public.place_reviews_cache (
    place_id TEXT PRIMARY KEY,
    reviews JSONB NOT NULL DEFAULT '[]'::jsonb,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_place_reviews_cache_expires_at 
    ON public.place_reviews_cache(expires_at);

-- Enable RLS
ALTER TABLE public.place_reviews_cache ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read cached reviews (public data)
DROP POLICY IF EXISTS "Anyone can read cached reviews" ON public.place_reviews_cache;
CREATE POLICY "Anyone can read cached reviews"
    ON public.place_reviews_cache
    FOR SELECT
    USING (true);

-- Policy: Allow anyone to cache reviews
DROP POLICY IF EXISTS "Anyone can cache reviews" ON public.place_reviews_cache;
CREATE POLICY "Anyone can cache reviews"
    ON public.place_reviews_cache
    FOR ALL
    USING (true);

-- ============================================
-- 6. FIX profiles TABLE - Add missing columns
-- ============================================
DO $$ 
BEGIN
    -- Add 'mood_streak' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'mood_streak'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN mood_streak INTEGER DEFAULT 0;
    END IF;

    -- Add 'followers_count' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'followers_count'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN followers_count INTEGER DEFAULT 0;
    END IF;

    -- Add 'following_count' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'following_count'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN following_count INTEGER DEFAULT 0;
    END IF;

    -- Add 'posts_count' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'posts_count'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN posts_count INTEGER DEFAULT 0;
    END IF;

    -- Add 'is_public' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'is_public'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN is_public BOOLEAN DEFAULT true;
    END IF;

    -- Add 'notification_preferences' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'notification_preferences'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN notification_preferences JSONB DEFAULT '{"push": true, "email": true}'::jsonb;
    END IF;

    -- Add 'theme_preference' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'theme_preference'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN theme_preference TEXT DEFAULT 'system';
    END IF;

    -- Add 'language_preference' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'language_preference'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN language_preference TEXT DEFAULT 'en';
    END IF;

    -- Add 'achievements' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'achievements'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN achievements TEXT[] DEFAULT ARRAY[]::TEXT[];
    END IF;

    -- Add 'favorite_mood' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'favorite_mood'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN favorite_mood TEXT;
    END IF;

    -- Add 'date_of_birth' column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'date_of_birth'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN date_of_birth DATE;
    END IF;
END $$;

-- Add image_url column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'image_url'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN image_url TEXT;
    END IF;
END $$;

-- ============================================
-- 7. CREATE STORAGE BUCKETS FOR PROFILE IMAGES
-- ============================================
-- IMPORTANT: Storage buckets must be created in Supabase Dashboard → Storage
-- SQL INSERT alone does NOT create the bucket. Use one of these methods:
--
-- Method 1 (Recommended): Supabase Dashboard
--   1. Go to Supabase Dashboard → Storage
--   2. Click "New bucket"
--   3. Name: "avatars"
--   4. Public: Yes
--   5. Click "Create bucket"
--
-- Method 2: Supabase CLI
--   supabase storage create avatars --public
--
-- Method 3: Management API (if you have access)
--   POST /storage/v1/bucket with body: {"name": "avatars", "public": true}
--
-- The SQL below will set up policies IF the bucket exists, but won't create it.

-- Try to create avatars bucket (will fail silently if bucket doesn't exist yet)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Storage policies for avatars bucket (only work if bucket exists)
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
  DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
  DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
  DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
  
  -- Create policies for avatars bucket
  -- Policy 1: Anyone can view/read avatar images (public bucket)
  CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');
  
  -- Policy 2: Authenticated users can upload to avatars bucket
  -- More permissive: any authenticated user can upload (app handles user-specific paths)
  CREATE POLICY "Authenticated users can upload avatars" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND 
    auth.role() = 'authenticated'
  );
  
  -- Policy 3: Users can update their own avatars (file path starts with their user ID)
  CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND 
    auth.role() = 'authenticated' AND
    name LIKE auth.uid()::text || '/%'
  );
  
  -- Policy 4: Users can delete their own avatars
  CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' AND 
    auth.role() = 'authenticated' AND
    name LIKE auth.uid()::text || '/%'
  );
END $$;

-- ============================================
-- COMPLETE!
-- ============================================
-- All missing tables and columns have been created/fixed
-- 
-- IMPORTANT: Create the 'avatars' storage bucket in Supabase Dashboard
-- The app should now work without database errors once the bucket is created


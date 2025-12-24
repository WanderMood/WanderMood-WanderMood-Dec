-- Fix Places Cache Schema Mismatch
-- This migration adds missing columns to match the expected schema

-- Add missing columns to places_cache table
DO $$ 
BEGIN
    -- Add latitude column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'latitude'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN latitude DECIMAL(10,7);
        
        RAISE NOTICE 'Added latitude column to places_cache table';
    ELSE
        RAISE NOTICE 'latitude column already exists in places_cache table';
    END IF;

    -- Add longitude column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'longitude'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN longitude DECIMAL(10,7);
        
        RAISE NOTICE 'Added longitude column to places_cache table';
    ELSE
        RAISE NOTICE 'longitude column already exists in places_cache table';
    END IF;

    -- Add name column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'name'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN name TEXT;
        
        RAISE NOTICE 'Added name column to places_cache table';
    ELSE
        RAISE NOTICE 'name column already exists in places_cache table';
    END IF;

    -- Add rating column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'rating'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN rating DECIMAL(3,2);
        
        RAISE NOTICE 'Added rating column to places_cache table';
    ELSE
        RAISE NOTICE 'rating column already exists in places_cache table';
    END IF;

    -- Add types column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'types'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN types TEXT[] DEFAULT '{}';
        
        RAISE NOTICE 'Added types column to places_cache table';
    ELSE
        RAISE NOTICE 'types column already exists in places_cache table';
    END IF;

    -- Add photo_reference column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'photo_reference'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN photo_reference TEXT;
        
        RAISE NOTICE 'Added photo_reference column to places_cache table';
    ELSE
        RAISE NOTICE 'photo_reference column already exists in places_cache table';
    END IF;

    -- Add photo_references column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'photo_references'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN photo_references TEXT[] DEFAULT '{}';
        
        RAISE NOTICE 'Added photo_references column to places_cache table';
    ELSE
        RAISE NOTICE 'photo_references column already exists in places_cache table';
    END IF;

    -- Add vicinity column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'vicinity'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN vicinity TEXT;
        
        RAISE NOTICE 'Added vicinity column to places_cache table';
    ELSE
        RAISE NOTICE 'vicinity column already exists in places_cache table';
    END IF;

    -- Add price_level column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'price_level'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN price_level INTEGER;
        
        RAISE NOTICE 'Added price_level column to places_cache table';
    ELSE
        RAISE NOTICE 'price_level column already exists in places_cache table';
    END IF;

    -- Add mood_tags column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'mood_tags'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN mood_tags TEXT[] DEFAULT '{}';
        
        RAISE NOTICE 'Added mood_tags column to places_cache table';
    ELSE
        RAISE NOTICE 'mood_tags column already exists in places_cache table';
    END IF;

    -- Add search_lat column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'search_lat'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN search_lat DECIMAL(10,7);
        
        RAISE NOTICE 'Added search_lat column to places_cache table';
    ELSE
        RAISE NOTICE 'search_lat column already exists in places_cache table';
    END IF;

    -- Add search_lng column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'search_lng'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN search_lng DECIMAL(10,7);
        
        RAISE NOTICE 'Added search_lng column to places_cache table';
    ELSE
        RAISE NOTICE 'search_lng column already exists in places_cache table';
    END IF;

END $$;

-- Create indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_places_cache_latitude_longitude 
ON public.places_cache (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_places_cache_mood_tags_gin 
ON public.places_cache USING GIN (mood_tags);

CREATE INDEX IF NOT EXISTS idx_places_cache_search_location 
ON public.places_cache (search_lat, search_lng);

CREATE INDEX IF NOT EXISTS idx_places_cache_types_gin 
ON public.places_cache USING GIN (types);

RAISE NOTICE 'Places cache schema fix completed successfully!'; 
-- Fix Places Cache Table Schema
-- This script adds missing columns to the places_cache table

-- Check if mood_tags column exists, and add it if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'mood_tags'
    ) THEN
        ALTER TABLE places_cache 
        ADD COLUMN mood_tags TEXT[] DEFAULT '{}';
        
        RAISE NOTICE 'Added mood_tags column to places_cache table';
    ELSE
        RAISE NOTICE 'mood_tags column already exists in places_cache table';
    END IF;
END $$;

-- Check if photo_references column exists, and add it if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'photo_references'
    ) THEN
        ALTER TABLE places_cache 
        ADD COLUMN photo_references TEXT[] DEFAULT '{}';
        
        RAISE NOTICE 'Added photo_references column to places_cache table';
    ELSE
        RAISE NOTICE 'photo_references column already exists in places_cache table';
    END IF;
END $$;

-- Check if search_lat and search_lng columns exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'search_lat'
    ) THEN
        ALTER TABLE places_cache 
        ADD COLUMN search_lat DOUBLE PRECISION;
        
        RAISE NOTICE 'Added search_lat column to places_cache table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'places_cache' 
        AND column_name = 'search_lng'
    ) THEN
        ALTER TABLE places_cache 
        ADD COLUMN search_lng DOUBLE PRECISION;
        
        RAISE NOTICE 'Added search_lng column to places_cache table';
    END IF;
END $$;

-- Create index on mood_tags for faster queries
CREATE INDEX IF NOT EXISTS idx_places_cache_mood_tags 
ON places_cache USING GIN (mood_tags);

-- Create index on location for distance queries
CREATE INDEX IF NOT EXISTS idx_places_cache_location 
ON places_cache (latitude, longitude);

-- Create index on updated_at for cache expiration queries
CREATE INDEX IF NOT EXISTS idx_places_cache_updated_at 
ON places_cache (updated_at);

RAISE NOTICE 'Places cache schema update completed successfully!'; 
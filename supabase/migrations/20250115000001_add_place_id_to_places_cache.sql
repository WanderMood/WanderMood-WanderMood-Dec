-- ============================================
-- Add place_id column to places_cache table
-- This migration ensures place_id exists and backfills from JSONB data
-- ============================================

-- Step 1: Add place_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'places_cache' 
        AND column_name = 'place_id'
    ) THEN
        ALTER TABLE public.places_cache 
        ADD COLUMN place_id TEXT;
        
        RAISE NOTICE 'Added place_id column to places_cache';
    ELSE
        RAISE NOTICE 'place_id column already exists in places_cache';
    END IF;
END $$;

-- Step 2: Create index on place_id for performance
CREATE INDEX IF NOT EXISTS idx_places_cache_place_id 
ON public.places_cache(place_id)
WHERE place_id IS NOT NULL;

-- Step 3: Backfill place_id from JSONB data for existing rows
-- Try multiple JSONB paths to find place_id
UPDATE public.places_cache
SET place_id = COALESCE(
    -- Try different JSONB paths where place_id might be stored
    -- All must use ->> to return TEXT (not JSONB)
    data->>'place_id',
    data->>'id',
    (data->'result')->>'place_id',
    (data->'result')->>'id',
    -- For arrays, try first element
    (data->0)->>'place_id',
    (data->0)->>'id',
    (data->'results'->0)->>'place_id',
    (data->'results'->0)->>'id'
)
WHERE place_id IS NULL 
  AND data IS NOT NULL;

-- Step 4: Log backfill results
DO $$
DECLARE
    backfilled_count INTEGER;
    total_count INTEGER;
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_count FROM public.places_cache;
    SELECT COUNT(*) INTO backfilled_count FROM public.places_cache WHERE place_id IS NOT NULL;
    SELECT COUNT(*) INTO null_count FROM public.places_cache WHERE place_id IS NULL;
    
    RAISE NOTICE 'places_cache statistics:';
    RAISE NOTICE '  Total rows: %', total_count;
    RAISE NOTICE '  Rows with place_id: %', backfilled_count;
    RAISE NOTICE '  Rows without place_id: %', null_count;
END $$;

-- Step 5: Add comment for documentation
COMMENT ON COLUMN public.places_cache.place_id IS 
'Google Place ID extracted from JSONB data. Used for fast lookups and joins. Populated automatically when inserting new cache entries.';


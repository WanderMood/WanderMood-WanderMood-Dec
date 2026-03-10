-- Add place_id and rating columns to scheduled_activities table
-- place_id: Google Place ID for fetching photos, open_now status, etc.
-- rating: Google Places rating to persist across save/load cycles

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'scheduled_activities'
        AND column_name = 'place_id'
    ) THEN
        ALTER TABLE public.scheduled_activities ADD COLUMN place_id TEXT;
        RAISE NOTICE 'Added place_id column to scheduled_activities';
    ELSE
        RAISE NOTICE 'place_id column already exists in scheduled_activities';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'scheduled_activities'
        AND column_name = 'rating'
    ) THEN
        ALTER TABLE public.scheduled_activities ADD COLUMN rating DOUBLE PRECISION;
        RAISE NOTICE 'Added rating column to scheduled_activities';
    ELSE
        RAISE NOTICE 'rating column already exists in scheduled_activities';
    END IF;
END $$;

-- Index on place_id for lookups
CREATE INDEX IF NOT EXISTS scheduled_activities_place_id_idx
ON public.scheduled_activities(place_id)
WHERE place_id IS NOT NULL;

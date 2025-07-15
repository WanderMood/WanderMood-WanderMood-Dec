-- Add onboarding fields to user_preferences table
-- This unifies the app settings and onboarding preferences systems

-- Add onboarding-specific columns
ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS mood TEXT;

ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS location TEXT;

ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS mood_preferences TEXT[] DEFAULT ARRAY[]::TEXT[];

ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS travel_styles TEXT[] DEFAULT ARRAY[]::TEXT[];

ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS social_vibe TEXT DEFAULT 'mixed';

-- Update the updated_at column to be automatically updated
ALTER TABLE public.user_preferences 
ALTER COLUMN updated_at SET DEFAULT NOW();

-- Create indexes for better performance on array columns
CREATE INDEX IF NOT EXISTS idx_user_preferences_mood_preferences 
ON public.user_preferences USING GIN(mood_preferences);

CREATE INDEX IF NOT EXISTS idx_user_preferences_travel_styles 
ON public.user_preferences USING GIN(travel_styles);

-- Verify all columns exist
DO $$ 
DECLARE
    missing_columns TEXT := '';
    column_list TEXT[] := ARRAY['interests', 'mood', 'location', 'mood_preferences', 'travel_styles', 'social_vibe'];
    col TEXT;
BEGIN 
    FOREACH col IN ARRAY column_list LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_preferences' 
            AND column_name = col
            AND table_schema = 'public'
        ) THEN 
            missing_columns := missing_columns || col || ', ';
        END IF;
    END LOOP;
    
    IF missing_columns = '' THEN
        RAISE NOTICE 'SUCCESS: All onboarding columns added to user_preferences table';
    ELSE
        RAISE NOTICE 'ERROR: Missing columns: %', missing_columns;
    END IF;
END $$; 
-- Add preferences fields for comprehensive preferences screen
-- Age group, activity pace, time available

-- Age Group (e.g., '18-24', '25-34', '35-44', '45-54', '55+')
ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS age_group TEXT;

-- Activity Pace (e.g., 'slow', 'moderate', 'active')
ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS activity_pace TEXT;

-- Time Available (e.g., 'quick', 'half-day', 'full-day')
ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS time_available TEXT;

-- Verify columns were added
DO $$ 
BEGIN 
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'age_group'
        AND table_schema = 'public'
    ) THEN 
        RAISE NOTICE 'SUCCESS: age_group column added to user_preferences table';
    ELSE 
        RAISE NOTICE 'ERROR: age_group column was not added';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'activity_pace'
        AND table_schema = 'public'
    ) THEN 
        RAISE NOTICE 'SUCCESS: activity_pace column added to user_preferences table';
    ELSE 
        RAISE NOTICE 'ERROR: activity_pace column was not added';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'time_available'
        AND table_schema = 'public'
    ) THEN 
        RAISE NOTICE 'SUCCESS: time_available column added to user_preferences table';
    ELSE 
        RAISE NOTICE 'ERROR: time_available column was not added';
    END IF;
END $$;
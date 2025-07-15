-- Add missing interests column to user_preferences table
-- This fixes the "Could not find the 'interests' column" error

ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS interests TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_preferences_interests 
ON public.user_preferences USING GIN(interests);

-- Verify the column was added (for debugging)
-- This will show in migration logs
DO $$ 
BEGIN 
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'interests'
        AND table_schema = 'public'
    ) THEN 
        RAISE NOTICE 'SUCCESS: interests column added to user_preferences table';
    ELSE 
        RAISE NOTICE 'ERROR: interests column was not added';
    END IF;
END $$; 
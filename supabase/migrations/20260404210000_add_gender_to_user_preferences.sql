-- Add gender field to user_preferences
-- Values: 'woman' | 'man' | 'non_binary' | 'prefer_not_to_say'
ALTER TABLE public.user_preferences
ADD COLUMN IF NOT EXISTS gender TEXT;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_preferences'
      AND column_name = 'gender'
  ) THEN
    RAISE NOTICE 'SUCCESS: gender column added to user_preferences table';
  ELSE
    RAISE WARNING 'FAILED: gender column not found in user_preferences table';
  END IF;
END $$;

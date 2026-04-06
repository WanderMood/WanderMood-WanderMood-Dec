-- ============================================
-- Verify and ensure profiles.image_url column exists
-- Standardize on image_url (not avatar_url)
-- ============================================

-- Step 1: Add image_url column if it doesn't exist
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
        
        RAISE NOTICE 'Added image_url column to profiles';
    ELSE
        RAISE NOTICE 'image_url column already exists in profiles';
    END IF;
END $$;

-- Step 2: Migrate data from avatar_url to image_url if needed
-- Only copy if image_url is NULL and avatar_url has a value
UPDATE public.profiles
SET image_url = avatar_url
WHERE image_url IS NULL 
  AND avatar_url IS NOT NULL;

-- Step 3: Create index on image_url for performance (if needed)
-- Note: Index on TEXT columns with many NULLs may not be necessary
-- CREATE INDEX IF NOT EXISTS idx_profiles_image_url 
-- ON public.profiles(image_url)
-- WHERE image_url IS NOT NULL;

-- Step 4: Add comment for documentation
COMMENT ON COLUMN public.profiles.image_url IS 
'URL to user profile image. Standardized column name (replaces avatar_url).';

-- Step 5: Log migration results
DO $$
DECLARE
    total_profiles INTEGER;
    profiles_with_image_url INTEGER;
    migrated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(*) INTO profiles_with_image_url FROM public.profiles WHERE image_url IS NOT NULL;
    SELECT COUNT(*) INTO migrated_count 
    FROM public.profiles 
    WHERE image_url IS NOT NULL 
      AND avatar_url IS NOT NULL 
      AND image_url = avatar_url;
    
    RAISE NOTICE 'profiles.image_url statistics:';
    RAISE NOTICE '  Total profiles: %', total_profiles;
    RAISE NOTICE '  Profiles with image_url: %', profiles_with_image_url;
    RAISE NOTICE '  Migrated from avatar_url: %', migrated_count;
END $$;


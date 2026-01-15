-- Add gender and location columns to profiles table
-- These columns were added in the Flutter code but not in the database

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('female', 'male', 'prefer_not_to_say'));

-- Note: location column may already exist, but ensure it's there
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS location TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.gender IS 'User gender preference: female, male, or prefer_not_to_say';
COMMENT ON COLUMN public.profiles.location IS 'User location (city, country, etc.)';


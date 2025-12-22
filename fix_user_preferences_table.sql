-- Fix user_preferences table schema
-- Add missing columns and fix data types

-- Step 1: Add text columns if they don't exist
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS communication_style TEXT DEFAULT 'friendly',
ADD COLUMN IF NOT EXISTS home_base TEXT DEFAULT 'Local Explorer',
ADD COLUMN IF NOT EXISTS planning_pace TEXT DEFAULT 'Same Day Planner',
ADD COLUMN IF NOT EXISTS budget_level TEXT DEFAULT 'Mid-Range',
ADD COLUMN IF NOT EXISTS language_preference TEXT DEFAULT 'en';

-- Step 2: Add boolean columns if they don't exist
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS has_completed_preferences BOOLEAN DEFAULT false;

-- Step 3: Add timestamp column if it doesn't exist
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Step 4: Fix JSONB columns - drop if they exist with wrong type, then recreate
-- This handles cases where columns exist as TEXT instead of JSONB
DO $$ 
BEGIN
    -- Drop and recreate selected_moods
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='selected_moods') THEN
        ALTER TABLE user_preferences DROP COLUMN selected_moods;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN selected_moods JSONB DEFAULT '[]'::jsonb;
    
    -- Drop and recreate travel_interests (was 'moods' in old schema)
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='moods') THEN
        ALTER TABLE user_preferences DROP COLUMN moods;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='travel_interests') THEN
        ALTER TABLE user_preferences DROP COLUMN travel_interests;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN travel_interests JSONB DEFAULT '[]'::jsonb;
    
    -- Drop and recreate social_vibe
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='social_vibe') THEN
        ALTER TABLE user_preferences DROP COLUMN social_vibe;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN social_vibe JSONB DEFAULT '[]'::jsonb;
    
    -- Drop and recreate travel_styles
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='travel_styles') THEN
        ALTER TABLE user_preferences DROP COLUMN travel_styles;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN travel_styles JSONB DEFAULT '[]'::jsonb;
    
    -- Drop and recreate favorite_moods
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='favorite_moods') THEN
        ALTER TABLE user_preferences DROP COLUMN favorite_moods;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN favorite_moods JSONB DEFAULT '[]'::jsonb;
    
    -- Drop and recreate preferred_time_slots
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='preferred_time_slots') THEN
        ALTER TABLE user_preferences DROP COLUMN preferred_time_slots;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN preferred_time_slots JSONB DEFAULT '["morning", "afternoon", "evening"]'::jsonb;
    
    -- Drop and recreate dietary_restrictions
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='dietary_restrictions') THEN
        ALTER TABLE user_preferences DROP COLUMN dietary_restrictions;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN dietary_restrictions JSONB DEFAULT '[]'::jsonb;
    
    -- Drop and recreate mobility_requirements
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='user_preferences' AND column_name='mobility_requirements') THEN
        ALTER TABLE user_preferences DROP COLUMN mobility_requirements;
    END IF;
    ALTER TABLE user_preferences ADD COLUMN mobility_requirements JSONB DEFAULT '[]'::jsonb;
END $$;

-- Step 5: Set default values for any NULL text/boolean columns
UPDATE user_preferences 
SET 
  communication_style = COALESCE(communication_style, 'friendly'),
  home_base = COALESCE(home_base, 'Local Explorer'),
  planning_pace = COALESCE(planning_pace, 'Same Day Planner'),
  budget_level = COALESCE(budget_level, 'Mid-Range'),
  language_preference = COALESCE(language_preference, 'en'),
  has_completed_onboarding = COALESCE(has_completed_onboarding, false),
  has_completed_preferences = COALESCE(has_completed_preferences, false),
  updated_at = COALESCE(updated_at, NOW())
WHERE 
  communication_style IS NULL OR
  home_base IS NULL OR
  planning_pace IS NULL OR
  budget_level IS NULL OR
  language_preference IS NULL OR
  has_completed_onboarding IS NULL OR
  has_completed_preferences IS NULL OR
  updated_at IS NULL;

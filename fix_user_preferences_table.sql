-- Fix user_preferences table by adding missing columns
-- Run this in your Supabase SQL Editor

-- First, let's see what columns exist
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_preferences';

-- Add missing columns to user_preferences table
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS communication_style TEXT DEFAULT 'friendly',
ADD COLUMN IF NOT EXISTS selected_moods JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS travel_interests JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS home_base TEXT DEFAULT 'Local Explorer',
ADD COLUMN IF NOT EXISTS social_vibe JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS planning_pace TEXT DEFAULT 'Same Day Planner',
ADD COLUMN IF NOT EXISTS travel_styles JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS budget_level TEXT DEFAULT 'Mid-Range',
ADD COLUMN IF NOT EXISTS favorite_moods JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS preferred_time_slots JSONB DEFAULT '["morning", "afternoon", "evening"]'::jsonb,
ADD COLUMN IF NOT EXISTS language_preference TEXT DEFAULT 'en',
ADD COLUMN IF NOT EXISTS dietary_restrictions JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS mobility_requirements JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS has_completed_preferences BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing records to have default values
UPDATE user_preferences 
SET 
  communication_style = COALESCE(communication_style, 'friendly'),
  selected_moods = COALESCE(selected_moods, '[]'::jsonb),
  travel_interests = COALESCE(travel_interests, '[]'::jsonb),
  home_base = COALESCE(home_base, 'Local Explorer'),
  social_vibe = COALESCE(social_vibe, '[]'::jsonb),
  planning_pace = COALESCE(planning_pace, 'Same Day Planner'),
  travel_styles = COALESCE(travel_styles, '[]'::jsonb),
  budget_level = COALESCE(budget_level, 'Mid-Range'),
  favorite_moods = COALESCE(favorite_moods, '[]'::jsonb),
  preferred_time_slots = COALESCE(preferred_time_slots, '["morning", "afternoon", "evening"]'::jsonb),
  language_preference = COALESCE(language_preference, 'en'),
  dietary_restrictions = COALESCE(dietary_restrictions, '[]'::jsonb),
  mobility_requirements = COALESCE(mobility_requirements, '[]'::jsonb),
  has_completed_onboarding = COALESCE(has_completed_onboarding, false),
  has_completed_preferences = COALESCE(has_completed_preferences, false),
  updated_at = COALESCE(updated_at, NOW());

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_preferences' 
ORDER BY ordinal_position; 
-- Enhanced user_preferences table for comprehensive onboarding data
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Communication & Style
  communication_style TEXT DEFAULT 'friendly',
  
  -- Onboarding Preferences
  selected_moods JSONB DEFAULT '[]'::jsonb,
  travel_interests JSONB DEFAULT '[]'::jsonb,
  home_base TEXT DEFAULT 'Local Explorer',
  social_vibe JSONB DEFAULT '[]'::jsonb,
  planning_pace TEXT DEFAULT 'Same Day Planner',
  travel_styles JSONB DEFAULT '[]'::jsonb,
  budget_level TEXT DEFAULT 'Mid-Range',
  
  -- AI-specific preferences
  favorite_moods JSONB DEFAULT '[]'::jsonb,
  preferred_time_slots JSONB DEFAULT '["morning", "afternoon", "evening"]'::jsonb,
  language_preference TEXT DEFAULT 'en',
  dietary_restrictions JSONB DEFAULT '[]'::jsonb,
  mobility_requirements JSONB DEFAULT '[]'::jsonb,
  
  -- Completion tracking
  has_completed_onboarding BOOLEAN DEFAULT false,
  has_completed_preferences BOOLEAN DEFAULT false,
  
  -- Legacy fields for backward compatibility
  analysis JSONB DEFAULT '{}'::jsonb,
  locations JSONB DEFAULT '[]'::jsonb,
  weather_data JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own preferences"
  ON user_preferences FOR SELECT
  USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert their own preferences"
  ON user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can update their own preferences"
  ON user_preferences FOR UPDATE
  USING (auth.uid() = user_id OR user_id IS NULL)
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can delete their own preferences"
  ON user_preferences FOR DELETE
  USING (auth.uid() = user_id OR user_id IS NULL);

-- Create updated_at trigger
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 
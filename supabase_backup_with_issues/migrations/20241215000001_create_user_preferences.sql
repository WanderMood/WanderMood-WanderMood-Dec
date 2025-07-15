-- Create user_preferences table for dynamic grouping personalization
CREATE TABLE user_preferences (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    preferred_activities TEXT[] DEFAULT '{}',
    preferred_venues TEXT[] DEFAULT '{}',
    visited_places TEXT[] DEFAULT '{}',
    saved_places TEXT[] DEFAULT '{}',
    energy_level_preference TEXT,
    social_preference TEXT,
    preferred_times_of_day TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create unique index on user_id
CREATE UNIQUE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

-- Enable RLS
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own preferences" ON user_preferences
    FOR DELETE USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_preferences_updated_at 
    BEFORE UPDATE ON user_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE user_preferences IS 'User preferences for personalized place recommendations and dynamic grouping';
COMMENT ON COLUMN user_preferences.preferred_activities IS 'Array of activity types user prefers (e.g., ["culture", "food", "outdoor"])';
COMMENT ON COLUMN user_preferences.preferred_venues IS 'Array of venue types user prefers (e.g., ["restaurant", "museum", "park"])';
COMMENT ON COLUMN user_preferences.visited_places IS 'Array of place IDs user has visited';
COMMENT ON COLUMN user_preferences.saved_places IS 'Array of place IDs user has saved/bookmarked';
COMMENT ON COLUMN user_preferences.energy_level_preference IS 'User preferred energy level: high, medium, low';
COMMENT ON COLUMN user_preferences.social_preference IS 'User social preference: social, solo, flexible';
COMMENT ON COLUMN user_preferences.preferred_times_of_day IS 'Array of preferred activity times (e.g., ["morning", "evening"])'; 
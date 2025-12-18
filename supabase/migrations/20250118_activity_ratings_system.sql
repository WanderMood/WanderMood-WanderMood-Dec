-- Activity Ratings System Migration
-- This adds comprehensive rating and pattern recognition capabilities

-- Activity Ratings Table
CREATE TABLE IF NOT EXISTS activity_ratings (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_id TEXT NOT NULL,
  activity_name TEXT NOT NULL,
  place_name TEXT,
  stars INTEGER NOT NULL CHECK (stars >= 1 AND stars <= 5),
  tags TEXT[] DEFAULT '{}',
  would_recommend BOOLEAN DEFAULT false,
  notes TEXT,
  completed_at TIMESTAMP NOT NULL DEFAULT NOW(),
  mood TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_activity_ratings_user_id ON activity_ratings(user_id);
CREATE INDEX idx_activity_ratings_activity_id ON activity_ratings(activity_id);
CREATE INDEX idx_activity_ratings_completed_at ON activity_ratings(completed_at DESC);
CREATE INDEX idx_activity_ratings_mood ON activity_ratings(mood);
CREATE INDEX idx_activity_ratings_stars ON activity_ratings(stars);

-- User Preference Patterns Table
CREATE TABLE IF NOT EXISTS user_preference_patterns (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  mood_activity_scores JSONB DEFAULT '{}',
  tag_counts JSONB DEFAULT '{}',
  time_preferences JSONB DEFAULT '{}',
  top_rated_places TEXT[] DEFAULT '{}',
  top_rated_activities TEXT[] DEFAULT '{}',
  last_updated TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for patterns
CREATE INDEX idx_preference_patterns_user_id ON user_preference_patterns(user_id);
CREATE INDEX idx_preference_patterns_last_updated ON user_preference_patterns(last_updated DESC);

-- Weekly Reflections Table
CREATE TABLE IF NOT EXISTS weekly_reflections (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start TIMESTAMP NOT NULL,
  week_end TIMESTAMP NOT NULL,
  activities_completed INTEGER DEFAULT 0,
  new_places_tried INTEGER DEFAULT 0,
  mood_distribution JSONB DEFAULT '{}',
  top_rated JSONB DEFAULT '[]',
  low_rated JSONB DEFAULT '[]',
  dominant_mood TEXT,
  achievements TEXT[] DEFAULT '{}',
  insights JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for reflections
CREATE INDEX idx_weekly_reflections_user_id ON weekly_reflections(user_id);
CREATE INDEX idx_weekly_reflections_week_start ON weekly_reflections(week_start DESC);

-- RLS Policies for Activity Ratings
ALTER TABLE activity_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own activity ratings"
  ON activity_ratings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activity ratings"
  ON activity_ratings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own activity ratings"
  ON activity_ratings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own activity ratings"
  ON activity_ratings FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for User Preference Patterns
ALTER TABLE user_preference_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own preference patterns"
  ON user_preference_patterns FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preference patterns"
  ON user_preference_patterns FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preference patterns"
  ON user_preference_patterns FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for Weekly Reflections
ALTER TABLE weekly_reflections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own weekly reflections"
  ON weekly_reflections FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own weekly reflections"
  ON weekly_reflections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own weekly reflections"
  ON weekly_reflections FOR UPDATE
  USING (auth.uid() = user_id);

-- Function to automatically update user patterns when rating is added
CREATE OR REPLACE FUNCTION update_user_patterns_on_rating()
RETURNS TRIGGER AS $$
BEGIN
  -- This is a placeholder trigger
  -- The actual pattern update logic is handled in the Dart service
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_patterns_on_rating
  AFTER INSERT ON activity_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_patterns_on_rating();

-- Grant permissions
GRANT ALL ON activity_ratings TO authenticated;
GRANT ALL ON user_preference_patterns TO authenticated;
GRANT ALL ON weekly_reflections TO authenticated;

-- Comments for documentation
COMMENT ON TABLE activity_ratings IS 'Stores user ratings for completed activities and places';
COMMENT ON TABLE user_preference_patterns IS 'ML-ready preference patterns derived from ratings';
COMMENT ON TABLE weekly_reflections IS 'Weekly summary of user activities and mood patterns';


-- Migration for Diary/Social System
-- Date: 2024-12-21

-- Enable PostGIS extension for geography type
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create trigger_set_timestamp function for updated_at columns
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Diary Entries Table
CREATE TABLE IF NOT EXISTS diary_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT,
  story TEXT NOT NULL,
  mood TEXT NOT NULL,
  location TEXT,
  location_coordinates GEOGRAPHY(POINT),
  tags TEXT[] DEFAULT '{}',
  photos TEXT[] DEFAULT '{}',
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for Diary Entries
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

-- Users can manage their own diary entries
CREATE POLICY "Users can manage own diary entries" 
ON diary_entries FOR ALL 
USING (auth.uid() = user_id);

-- Users can view public diary entries
CREATE POLICY "Users can view public diary entries" 
ON diary_entries FOR SELECT 
USING (is_public = true);

-- Diary Likes Table
CREATE TABLE IF NOT EXISTS diary_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  diary_entry_id UUID REFERENCES diary_entries(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, diary_entry_id)
);

-- Row Level Security for Diary Likes
ALTER TABLE diary_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own likes" 
ON diary_likes FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Public read access for likes" 
ON diary_likes FOR SELECT 
USING (true);

-- Diary Comments Table
CREATE TABLE IF NOT EXISTS diary_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  diary_entry_id UUID REFERENCES diary_entries(id) NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for Diary Comments
ALTER TABLE diary_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own comments" 
ON diary_comments FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Public read access for comments" 
ON diary_comments FOR SELECT 
USING (true);

-- User Follows Table (for friend system)
CREATE TABLE IF NOT EXISTS user_follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID REFERENCES auth.users(id) NOT NULL,
  following_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK(follower_id != following_id)
);

-- Row Level Security for User Follows
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own follows" 
ON user_follows FOR ALL 
USING (auth.uid() = follower_id);

CREATE POLICY "Public read access for follows" 
ON user_follows FOR SELECT 
USING (true);

-- Saved Diary Entries Table
CREATE TABLE IF NOT EXISTS saved_diary_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  diary_entry_id UUID REFERENCES diary_entries(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, diary_entry_id)
);

-- Row Level Security for Saved Diary Entries
ALTER TABLE saved_diary_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own saved entries" 
ON saved_diary_entries FOR ALL 
USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_diary_entries_user_id ON diary_entries(user_id);
CREATE INDEX idx_diary_entries_created_at ON diary_entries(created_at DESC);
CREATE INDEX idx_diary_entries_location ON diary_entries USING GIST(location_coordinates);
CREATE INDEX idx_diary_entries_tags ON diary_entries USING GIN(tags);
CREATE INDEX idx_diary_entries_public ON diary_entries(is_public) WHERE is_public = true;

CREATE INDEX idx_diary_likes_entry_id ON diary_likes(diary_entry_id);
CREATE INDEX idx_diary_likes_user_id ON diary_likes(user_id);

CREATE INDEX idx_diary_comments_entry_id ON diary_comments(diary_entry_id);
CREATE INDEX idx_diary_comments_user_id ON diary_comments(user_id);

CREATE INDEX idx_user_follows_follower ON user_follows(follower_id);
CREATE INDEX idx_user_follows_following ON user_follows(following_id);

CREATE INDEX idx_saved_entries_user_id ON saved_diary_entries(user_id);

-- Create updated_at trigger for diary entries
CREATE TRIGGER set_timestamp_diary_entries
  BEFORE UPDATE ON diary_entries
  FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Create updated_at trigger for diary comments  
CREATE TRIGGER set_timestamp_diary_comments
  BEFORE UPDATE ON diary_comments
  FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Create function to get diary entry with counts
CREATE OR REPLACE FUNCTION get_diary_entry_with_stats(entry_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  title TEXT,
  story TEXT,
  mood TEXT,
  location TEXT,
  location_coordinates GEOGRAPHY,
  tags TEXT[],
  photos TEXT[],
  is_public BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  likes_count BIGINT,
  comments_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    de.id,
    de.user_id,
    de.title,
    de.story,
    de.mood,
    de.location,
    de.location_coordinates,
    de.tags,
    de.photos,
    de.is_public,
    de.created_at,
    de.updated_at,
    COALESCE(likes.count, 0) as likes_count,
    COALESCE(comments.count, 0) as comments_count
  FROM diary_entries de
  LEFT JOIN (
    SELECT diary_entry_id, COUNT(*) as count
    FROM diary_likes
    WHERE diary_entry_id = entry_id
    GROUP BY diary_entry_id
  ) likes ON de.id = likes.diary_entry_id
  LEFT JOIN (
    SELECT diary_entry_id, COUNT(*) as count
    FROM diary_comments
    WHERE diary_entry_id = entry_id
    GROUP BY diary_entry_id
  ) comments ON de.id = comments.diary_entry_id
  WHERE de.id = entry_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 
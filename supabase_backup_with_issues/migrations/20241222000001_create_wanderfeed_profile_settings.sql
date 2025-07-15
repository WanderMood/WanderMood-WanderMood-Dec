-- WanderFeed Profile Settings Migration
-- Date: 2024-12-22
-- Purpose: Add comprehensive profile settings functionality for WanderFeed

-- First, extend the profiles table with new WanderFeed-specific fields
DO $$ 
BEGIN 
    -- Add travel bio field if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'travel_bio'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN travel_bio TEXT DEFAULT 'Ready to explore the world! ✈️';
    END IF;

    -- Add currently_exploring field if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'currently_exploring'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN currently_exploring TEXT;
    END IF;

    -- Add travel_vibes field if it doesn't exist (JSONB array of selected vibes)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'travel_vibes'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN travel_vibes JSONB DEFAULT '["Adventurous", "Cultural", "Peaceful"]'::jsonb;
    END IF;

    -- Add privacy_settings field if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'privacy_settings'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN privacy_settings JSONB DEFAULT '{
            "profile_visibility": "public",
            "story_visibility": "public", 
            "location_sharing": true,
            "activity_status": true,
            "allow_messages": true,
            "show_followers": true
        }'::jsonb;
    END IF;

    -- Add travel_dna field if it doesn't exist (personality breakdown)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'travel_dna'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN travel_dna JSONB DEFAULT '{
            "adventure": 75,
            "culture": 60, 
            "relaxation": 85
        }'::jsonb;
    END IF;

    -- Add mood_of_month field if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'mood_of_month'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN mood_of_month JSONB DEFAULT '{
            "mood": "Peaceful",
            "month": "December",
            "description": "Mostly Peaceful this December"
        }'::jsonb;
    END IF;
END $$;

-- Create saved_folders table for organizing saved diary entries
CREATE TABLE IF NOT EXISTS saved_folders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#6366f1', -- Default indigo color
    icon TEXT DEFAULT '📁',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add folder_id to saved_diary_entries table
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'saved_diary_entries' AND column_name = 'folder_id'
    ) THEN
        ALTER TABLE saved_diary_entries ADD COLUMN folder_id UUID REFERENCES saved_folders(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Create wander_badges table for achievements system
CREATE TABLE IF NOT EXISTS wander_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    badge_key TEXT UNIQUE NOT NULL, -- e.g., 'first_post', 'hidden_gem_hunter'
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    category TEXT DEFAULT 'general', -- general, travel, social, content
    requirement_type TEXT NOT NULL, -- count, location, streak, special
    requirement_value INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_badges table for tracking user achievements
CREATE TABLE IF NOT EXISTS user_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    badge_id UUID REFERENCES wander_badges(id) NOT NULL,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress INTEGER DEFAULT 0, -- For tracking progress towards badge
    UNIQUE(user_id, badge_id)
);

-- Create travel_mood_preferences table for detailed mood settings
CREATE TABLE IF NOT EXISTS travel_mood_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    mood_categories JSONB DEFAULT '{
        "adventure": {"enabled": true, "weight": 1.0},
        "cultural": {"enabled": true, "weight": 1.0},
        "relaxation": {"enabled": true, "weight": 1.0},
        "social": {"enabled": true, "weight": 1.0},
        "spontaneous": {"enabled": true, "weight": 1.0},
        "romantic": {"enabled": true, "weight": 1.0}
    }'::jsonb,
    activity_preferences JSONB DEFAULT '{
        "time_of_day": ["morning", "afternoon", "evening"],
        "duration": ["quick", "half_day", "full_day"],
        "group_size": ["solo", "couple", "small_group", "large_group"],
        "budget_range": ["budget", "moderate", "luxury"]
    }'::jsonb,
    notification_triggers JSONB DEFAULT '{
        "new_recommendations": true,
        "mood_reminders": true,
        "weather_updates": true,
        "friend_activities": true
    }'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for new tables
ALTER TABLE saved_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE wander_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE travel_mood_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for saved_folders
CREATE POLICY "Users can manage own folders" 
ON saved_folders FOR ALL 
USING (auth.uid() = user_id);

-- RLS Policies for wander_badges (read-only for users)
CREATE POLICY "Public read access for badges" 
ON wander_badges FOR SELECT 
USING (is_active = true);

-- RLS Policies for user_badges
CREATE POLICY "Users can view own badges" 
ON user_badges FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own badge progress" 
ON user_badges FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "System can insert user badges" 
ON user_badges FOR INSERT 
WITH CHECK (true); -- Allow system to award badges

-- RLS Policies for travel_mood_preferences
CREATE POLICY "Users can manage own mood preferences" 
ON travel_mood_preferences FOR ALL 
USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_saved_folders_user_id ON saved_folders(user_id);
CREATE INDEX idx_saved_diary_entries_folder_id ON saved_diary_entries(folder_id) WHERE folder_id IS NOT NULL;
CREATE INDEX idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX idx_user_badges_badge_id ON user_badges(badge_id);
CREATE INDEX idx_travel_mood_preferences_user_id ON travel_mood_preferences(user_id);

-- Create updated_at triggers
CREATE TRIGGER set_timestamp_saved_folders
    BEFORE UPDATE ON saved_folders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_timestamp_travel_mood_preferences
    BEFORE UPDATE ON travel_mood_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default wander badges
INSERT INTO wander_badges (badge_key, name, description, icon, color, category, requirement_type, requirement_value) VALUES
('first_post', 'First Post', 'Shared your first WanderFeed story', '🎉', '#10B981', 'content', 'count', 1),
('hidden_gem_hunter', 'Hidden Gem Hunter', 'Discovered 10 unique places', '💎', '#8B5CF6', 'travel', 'count', 10),
('foodie_explorer', 'Foodie Explorer', 'Shared 15 food experiences', '🍴', '#F59E0B', 'travel', 'count', 15),
('social_butterfly', 'Social Butterfly', 'Connected with 25 wanderers', '🦋', '#EC4899', 'social', 'count', 25),
('globe_trotter', 'Globe Trotter', 'Visited 20 different cities', '🌍', '#3B82F6', 'travel', 'count', 20)
ON CONFLICT (badge_key) DO NOTHING;

-- Create function to calculate travel DNA based on user activity
CREATE OR REPLACE FUNCTION calculate_travel_dna(user_uuid UUID)
RETURNS JSONB AS $$
DECLARE
    adventure_score INTEGER := 50;
    culture_score INTEGER := 50;
    relaxation_score INTEGER := 50;
    mood_counts RECORD;
BEGIN
    -- Calculate scores based on diary entry moods
    SELECT 
        COUNT(CASE WHEN mood IN ('Adventurous', 'Spontaneous') THEN 1 END) as adventure_count,
        COUNT(CASE WHEN mood IN ('Cultural', 'Curious') THEN 1 END) as culture_count,
        COUNT(CASE WHEN mood IN ('Peaceful', 'Relaxed', 'Romantic') THEN 1 END) as relaxation_count,
        COUNT(*) as total_count
    INTO mood_counts
    FROM diary_entries 
    WHERE user_id = user_uuid AND created_at > NOW() - INTERVAL '6 months';

    -- Calculate percentages with minimum baseline
    IF mood_counts.total_count > 0 THEN
        adventure_score := GREATEST(30, LEAST(100, 50 + (mood_counts.adventure_count * 50 / mood_counts.total_count)));
        culture_score := GREATEST(30, LEAST(100, 50 + (mood_counts.culture_count * 50 / mood_counts.total_count)));
        relaxation_score := GREATEST(30, LEAST(100, 50 + (mood_counts.relaxation_count * 50 / mood_counts.total_count)));
    END IF;

    RETURN jsonb_build_object(
        'adventure', adventure_score,
        'culture', culture_score,
        'relaxation', relaxation_score
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update mood of month automatically
CREATE OR REPLACE FUNCTION update_mood_of_month(user_uuid UUID)
RETURNS JSONB AS $$
DECLARE
    top_mood TEXT;
    current_month TEXT;
    mood_description TEXT;
BEGIN
    -- Get current month name
    current_month := TO_CHAR(NOW(), 'Month');
    
    -- Get most frequent mood this month
    SELECT mood INTO top_mood
    FROM diary_entries 
    WHERE user_id = user_uuid 
        AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW())
    GROUP BY mood 
    ORDER BY COUNT(*) DESC 
    LIMIT 1;

    -- Default to peaceful if no entries
    IF top_mood IS NULL THEN
        top_mood := 'Peaceful';
    END IF;

    mood_description := 'Mostly ' || top_mood || ' this ' || TRIM(current_month);

    RETURN jsonb_build_object(
        'mood', top_mood,
        'month', TRIM(current_month),
        'description', mood_description
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to award badges automatically
CREATE OR REPLACE FUNCTION check_and_award_badges(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
    badge_record RECORD;
    user_count INTEGER;
    user_progress INTEGER;
BEGIN
    -- Loop through all active badges
    FOR badge_record IN 
        SELECT * FROM wander_badges WHERE is_active = true
    LOOP
        -- Check if user already has this badge
        IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = user_uuid AND badge_id = badge_record.id) THEN
            
            -- Calculate progress based on badge requirement
            CASE badge_record.badge_key
                WHEN 'first_post' THEN
                    SELECT COUNT(*) INTO user_count FROM diary_entries WHERE user_id = user_uuid;
                WHEN 'hidden_gem_hunter' THEN
                    SELECT COUNT(DISTINCT location) INTO user_count FROM diary_entries WHERE user_id = user_uuid AND location IS NOT NULL;
                WHEN 'foodie_explorer' THEN
                    SELECT COUNT(*) INTO user_count FROM diary_entries WHERE user_id = user_uuid AND 'food' = ANY(tags);
                WHEN 'social_butterfly' THEN
                    SELECT followers_count INTO user_count FROM profiles WHERE id = user_uuid;
                WHEN 'globe_trotter' THEN
                    SELECT COUNT(DISTINCT location) INTO user_count FROM diary_entries WHERE user_id = user_uuid AND location IS NOT NULL;
                ELSE
                    user_count := 0;
            END CASE;

            -- Insert or update progress
            INSERT INTO user_badges (user_id, badge_id, progress, earned_at)
            VALUES (
                user_uuid, 
                badge_record.id, 
                user_count,
                CASE WHEN user_count >= badge_record.requirement_value THEN NOW() ELSE NULL END
            )
            ON CONFLICT (user_id, badge_id) DO UPDATE SET
                progress = EXCLUDED.progress,
                earned_at = CASE WHEN EXCLUDED.progress >= badge_record.requirement_value THEN NOW() ELSE user_badges.earned_at END;
                
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 
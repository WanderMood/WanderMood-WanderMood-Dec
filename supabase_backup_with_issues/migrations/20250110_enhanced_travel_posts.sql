-- Enhanced Travel Posts System
-- Builds on existing diary_entries table with travel-specific enhancements

-- Enhanced diary entries with travel features
ALTER TABLE diary_entries 
ADD COLUMN IF NOT EXISTS weather_data JSONB,
ADD COLUMN IF NOT EXISTS travel_companions TEXT[],
ADD COLUMN IF NOT EXISTS budget_spent DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS currency_code TEXT DEFAULT 'EUR',
ADD COLUMN IF NOT EXISTS activities TEXT[],
ADD COLUMN IF NOT EXISTS rating INTEGER CHECK (rating >= 1 AND rating <= 5),
ADD COLUMN IF NOT EXISTS travel_tips TEXT,
ADD COLUMN IF NOT EXISTS best_time_to_visit TEXT,
ADD COLUMN IF NOT EXISTS location_details JSONB, -- Detailed location info from Google Places
ADD COLUMN IF NOT EXISTS privacy_level TEXT DEFAULT 'public' CHECK (privacy_level IN ('public', 'friends', 'private')),
ADD COLUMN IF NOT EXISTS featured_photo_url TEXT,
ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS share_count INTEGER DEFAULT 0;

-- Create storage bucket for travel photos
INSERT INTO storage.buckets (id, name, public) 
VALUES ('travel-photos', 'travel-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for travel photos
CREATE POLICY "Travel photos are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'travel-photos');

CREATE POLICY "Users can upload their own travel photos" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'travel-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own travel photos" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'travel-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own travel photos" ON storage.objects
FOR DELETE USING (
    bucket_id = 'travel-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Enhanced reactions system (beyond just likes)
CREATE TABLE IF NOT EXISTS post_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    diary_entry_id UUID REFERENCES diary_entries(id) ON DELETE CASCADE,
    reaction_type TEXT NOT NULL CHECK (reaction_type IN ('love', 'wow', 'wanderlust', 'helpful', 'inspiring')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, diary_entry_id) -- One reaction per user per post
);

-- RLS for reactions
ALTER TABLE post_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own reactions" ON post_reactions
FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Public read access for reactions" ON post_reactions
FOR SELECT USING (true);

-- Travel itinerary items (detailed activities within a post)
CREATE TABLE IF NOT EXISTS itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diary_entry_id UUID REFERENCES diary_entries(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    location_coordinates GEOGRAPHY(POINT),
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    cost DECIMAL(10,2),
    category TEXT, -- restaurant, attraction, accommodation, transport, etc.
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    photos TEXT[],
    tips TEXT,
    booking_url TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for itinerary items
ALTER TABLE itinerary_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own itinerary items" ON itinerary_items
FOR ALL USING (
    auth.uid() = (
        SELECT user_id FROM diary_entries 
        WHERE id = itinerary_items.diary_entry_id
    )
);

CREATE POLICY "Public read access for itinerary items" ON itinerary_items
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM diary_entries 
        WHERE id = itinerary_items.diary_entry_id 
        AND (is_public = true OR privacy_level = 'public')
    )
);

-- Travel expenses tracking
CREATE TABLE IF NOT EXISTS travel_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diary_entry_id UUID REFERENCES diary_entries(id) ON DELETE CASCADE,
    category TEXT NOT NULL, -- food, transport, accommodation, activities, shopping, etc.
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,
    currency_code TEXT DEFAULT 'EUR',
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    location TEXT,
    receipt_url TEXT, -- Link to receipt photo in storage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for expenses
ALTER TABLE travel_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own expenses" ON travel_expenses
FOR ALL USING (
    auth.uid() = (
        SELECT user_id FROM diary_entries 
        WHERE id = travel_expenses.diary_entry_id
    )
);

-- Post collections/albums
CREATE TABLE IF NOT EXISTS post_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    cover_photo_url TEXT,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Collection items (many-to-many between collections and posts)
CREATE TABLE IF NOT EXISTS collection_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID REFERENCES post_collections(id) ON DELETE CASCADE,
    diary_entry_id UUID REFERENCES diary_entries(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(collection_id, diary_entry_id)
);

-- RLS for collections
ALTER TABLE post_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own collections" ON post_collections
FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Public read access for public collections" ON post_collections
FOR SELECT USING (is_public = true);

CREATE POLICY "Users can manage own collection items" ON collection_items
FOR ALL USING (
    auth.uid() = (
        SELECT user_id FROM post_collections 
        WHERE id = collection_items.collection_id
    )
);

-- Enhanced indexes for performance
CREATE INDEX idx_diary_entries_privacy ON diary_entries(privacy_level);
CREATE INDEX idx_diary_entries_rating ON diary_entries(rating DESC) WHERE rating IS NOT NULL;
CREATE INDEX idx_diary_entries_activities ON diary_entries USING GIN(activities);
CREATE INDEX idx_diary_entries_weather ON diary_entries USING GIN(weather_data);
CREATE INDEX idx_diary_entries_view_count ON diary_entries(view_count DESC);

CREATE INDEX idx_post_reactions_type ON post_reactions(reaction_type);
CREATE INDEX idx_post_reactions_entry_id ON post_reactions(diary_entry_id);

CREATE INDEX idx_itinerary_items_entry_id ON itinerary_items(diary_entry_id);
CREATE INDEX idx_itinerary_items_order ON itinerary_items(diary_entry_id, order_index);
CREATE INDEX idx_itinerary_items_category ON itinerary_items(category);

CREATE INDEX idx_travel_expenses_entry_id ON travel_expenses(diary_entry_id);
CREATE INDEX idx_travel_expenses_category ON travel_expenses(category);

-- Functions for enhanced functionality

-- Function to increment view count
CREATE OR REPLACE FUNCTION increment_post_view_count(post_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE diary_entries 
    SET view_count = view_count + 1 
    WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get post with full stats
CREATE OR REPLACE FUNCTION get_post_with_full_stats(post_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title TEXT,
    story TEXT,
    mood TEXT,
    location TEXT,
    location_coordinates GEOGRAPHY,
    location_details JSONB,
    weather_data JSONB,
    tags TEXT[],
    photos TEXT[],
    activities TEXT[],
    rating INTEGER,
    privacy_level TEXT,
    featured_photo_url TEXT,
    view_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    likes_count BIGINT,
    reactions_count BIGINT,
    comments_count BIGINT,
    total_expenses DECIMAL
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
        de.location_details,
        de.weather_data,
        de.tags,
        de.photos,
        de.activities,
        de.rating,
        de.privacy_level,
        de.featured_photo_url,
        de.view_count,
        de.created_at,
        de.updated_at,
        COALESCE(likes.count, 0) as likes_count,
        COALESCE(reactions.count, 0) as reactions_count,
        COALESCE(comments.count, 0) as comments_count,
        COALESCE(expenses.total, 0) as total_expenses
    FROM diary_entries de
    LEFT JOIN (
        SELECT diary_entry_id, COUNT(*) as count
        FROM diary_likes
        WHERE diary_entry_id = post_id
        GROUP BY diary_entry_id
    ) likes ON de.id = likes.diary_entry_id
    LEFT JOIN (
        SELECT diary_entry_id, COUNT(*) as count
        FROM post_reactions
        WHERE diary_entry_id = post_id
        GROUP BY diary_entry_id
    ) reactions ON de.id = reactions.diary_entry_id
    LEFT JOIN (
        SELECT diary_entry_id, COUNT(*) as count
        FROM diary_comments
        WHERE diary_entry_id = post_id
        GROUP BY diary_entry_id
    ) comments ON de.id = comments.diary_entry_id
    LEFT JOIN (
        SELECT diary_entry_id, SUM(amount) as total
        FROM travel_expenses
        WHERE diary_entry_id = post_id
        GROUP BY diary_entry_id
    ) expenses ON de.id = expenses.diary_entry_id
    WHERE de.id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get trending posts (based on recent activity)
CREATE OR REPLACE FUNCTION get_trending_posts(days_back INTEGER DEFAULT 7, limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
    post_id UUID,
    score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        de.id as post_id,
        (
            (COALESCE(recent_likes.count, 0) * 1.0) +
            (COALESCE(recent_reactions.count, 0) * 1.5) +
            (COALESCE(recent_comments.count, 0) * 2.0) +
            (de.view_count * 0.1) +
            (CASE WHEN de.rating >= 4 THEN 5.0 ELSE 0 END)
        ) as score
    FROM diary_entries de
    LEFT JOIN (
        SELECT diary_entry_id, COUNT(*) as count
        FROM diary_likes
        WHERE created_at >= NOW() - INTERVAL '%s days' % days_back
        GROUP BY diary_entry_id
    ) recent_likes ON de.id = recent_likes.diary_entry_id
    LEFT JOIN (
        SELECT diary_entry_id, COUNT(*) as count
        FROM post_reactions
        WHERE created_at >= NOW() - INTERVAL '%s days' % days_back
        GROUP BY diary_entry_id
    ) recent_reactions ON de.id = recent_reactions.diary_entry_id
    LEFT JOIN (
        SELECT diary_entry_id, COUNT(*) as count
        FROM diary_comments
        WHERE created_at >= NOW() - INTERVAL '%s days' % days_back
        GROUP BY diary_entry_id
    ) recent_comments ON de.id = recent_comments.diary_entry_id
    WHERE de.privacy_level = 'public'
    AND de.created_at >= NOW() - INTERVAL '%s days' % (days_back * 2)
    ORDER BY score DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 
-- Enhanced Places Cache Table Schema for WanderMood
-- Supports multiple photo references and improved photo management
-- Updated: December 2024

-- Create the enhanced places_cache table
CREATE TABLE IF NOT EXISTS places_cache (
    id BIGSERIAL PRIMARY KEY,
    place_id TEXT NOT NULL,
    name TEXT NOT NULL,
    rating DECIMAL(3,2),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    types TEXT[] DEFAULT '{}',
    photo_reference TEXT, -- Primary photo reference (first/best)
    photo_references TEXT[] DEFAULT '{}', -- All available photo references
    vicinity TEXT,
    price_level INTEGER,
    mood_tags TEXT[] NOT NULL DEFAULT '{}',
    search_lat DECIMAL(10,7) NOT NULL,
    search_lng DECIMAL(10,7) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_places_cache_mood_tags ON places_cache USING GIN (mood_tags);
CREATE INDEX IF NOT EXISTS idx_places_cache_location ON places_cache (search_lat, search_lng);
CREATE INDEX IF NOT EXISTS idx_places_cache_place_id ON places_cache (place_id);
CREATE INDEX IF NOT EXISTS idx_places_cache_user_id ON places_cache (user_id);
CREATE INDEX IF NOT EXISTS idx_places_cache_created_at ON places_cache (created_at);
CREATE INDEX IF NOT EXISTS idx_places_cache_types ON places_cache USING GIN (types);
CREATE INDEX IF NOT EXISTS idx_places_cache_rating ON places_cache (rating);

-- Enable Row Level Security
ALTER TABLE places_cache ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own cached places" ON places_cache
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cached places" ON places_cache
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cached places" ON places_cache
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cached places" ON places_cache
    FOR DELETE USING (auth.uid() = user_id);

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_places_cache_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic timestamp updates
DROP TRIGGER IF EXISTS update_places_cache_timestamp_trigger ON places_cache;
CREATE TRIGGER update_places_cache_timestamp_trigger
    BEFORE UPDATE ON places_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_places_cache_timestamp();

-- Function to clean up old cache entries (older than 14 days)
CREATE OR REPLACE FUNCTION cleanup_old_places_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM places_cache
    WHERE created_at < NOW() - INTERVAL '14 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get cache statistics with photo info
CREATE OR REPLACE FUNCTION get_places_cache_stats(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
    total_places BIGINT,
    places_with_photos BIGINT,
    places_with_multiple_photos BIGINT,
    avg_photos_per_place DECIMAL,
    unique_moods BIGINT,
    cache_size_mb DECIMAL,
    oldest_entry TIMESTAMP,
    newest_entry TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_places,
        COUNT(*) FILTER (WHERE photo_reference IS NOT NULL) as places_with_photos,
        COUNT(*) FILTER (WHERE array_length(photo_references, 1) > 1) as places_with_multiple_photos,
        AVG(COALESCE(array_length(photo_references, 1), 0))::DECIMAL as avg_photos_per_place,
        COUNT(DISTINCT unnest_mood) as unique_moods,
        (pg_total_relation_size('places_cache') / 1024.0 / 1024.0)::DECIMAL as cache_size_mb,
        MIN(created_at) as oldest_entry,
        MAX(created_at) as newest_entry
    FROM places_cache
    CROSS JOIN LATERAL unnest(mood_tags) as unnest_mood
    WHERE (p_user_id IS NULL OR user_id = p_user_id);
END;
$$ LANGUAGE plpgsql;

-- Function to get photo quality statistics
CREATE OR REPLACE FUNCTION get_photo_quality_stats(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
    total_photos BIGINT,
    places_with_photos_pct DECIMAL,
    avg_photos_per_venue DECIMAL,
    venues_with_fallback_only BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH photo_stats AS (
        SELECT 
            place_id,
            photo_reference IS NOT NULL as has_primary_photo,
            COALESCE(array_length(photo_references, 1), 0) as photo_count
        FROM places_cache
        WHERE (p_user_id IS NULL OR user_id = p_user_id)
    )
    SELECT 
        SUM(photo_count) as total_photos,
        (COUNT(*) FILTER (WHERE has_primary_photo) * 100.0 / COUNT(*))::DECIMAL as places_with_photos_pct,
        AVG(photo_count)::DECIMAL as avg_photos_per_venue,
        COUNT(*) FILTER (WHERE NOT has_primary_photo) as venues_with_fallback_only
    FROM photo_stats;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up old entries (runs daily at 2 AM)
-- Note: This requires pg_cron extension to be enabled
-- SELECT cron.schedule('cleanup-places-cache', '0 2 * * *', 'SELECT cleanup_old_places_cache();');

-- Sample usage examples:
-- 
-- 1. Insert a place with multiple photos:
-- INSERT INTO places_cache (place_id, name, rating, latitude, longitude, types, photo_reference, photo_references, mood_tags, search_lat, search_lng, user_id)
-- VALUES ('ChIJ123', 'Amazing Restaurant', 4.5, 51.9225, 4.4792, ARRAY['restaurant'], 'photo_ref_1', ARRAY['photo_ref_1', 'photo_ref_2', 'photo_ref_3'], ARRAY['romantic', 'foody'], 51.9225, 4.4792, auth.uid());
--
-- 2. Get cache statistics:
-- SELECT * FROM get_places_cache_stats();
--
-- 3. Get photo quality statistics:
-- SELECT * FROM get_photo_quality_stats();
--
-- 4. Clean up old entries manually:
-- SELECT cleanup_old_places_cache();
--
-- 5. Query places with multiple photos:
-- SELECT name, array_length(photo_references, 1) as photo_count 
-- FROM places_cache 
-- WHERE array_length(photo_references, 1) > 1 
-- ORDER BY photo_count DESC; 
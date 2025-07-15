-- Create places cache table for caching Google Places API responses
CREATE TABLE IF NOT EXISTS places_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT NOT NULL UNIQUE,
    data JSONB NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    request_type TEXT NOT NULL CHECK (request_type IN ('search', 'autocomplete', 'details', 'photos', 'nearby')),
    query TEXT,
    place_id TEXT,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS policies for places cache
ALTER TABLE places_cache ENABLE ROW LEVEL SECURITY;

-- Users can only access their own cached places data
CREATE POLICY "Users can access own places cache" ON places_cache
    FOR ALL USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_places_cache_key ON places_cache(cache_key);
CREATE INDEX idx_places_cache_user_id ON places_cache(user_id);
CREATE INDEX idx_places_cache_expires_at ON places_cache(expires_at);
CREATE INDEX idx_places_cache_request_type ON places_cache(request_type);
CREATE INDEX idx_places_cache_location ON places_cache(location_lat, location_lng);

-- Create trigger for updated_at
CREATE TRIGGER update_places_cache_updated_at
    BEFORE UPDATE ON places_cache
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Create cleanup function for expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_places_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM places_cache WHERE expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Comment for documentation
COMMENT ON TABLE places_cache IS 'Cache table for Google Places API responses to improve performance and reduce API calls';
COMMENT ON FUNCTION cleanup_expired_places_cache() IS 'Function to clean up expired places cache entries'; 
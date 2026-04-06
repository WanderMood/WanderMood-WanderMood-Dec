-- Create weather cache table for caching API responses
CREATE TABLE IF NOT EXISTS weather_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT NOT NULL UNIQUE,
    data JSONB NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    location_lat DECIMAL(10, 8) NOT NULL,
    location_lng DECIMAL(11, 8) NOT NULL,
    weather_type TEXT NOT NULL CHECK (weather_type IN ('current', 'forecast', 'onecall')),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS policies for weather cache
ALTER TABLE weather_cache ENABLE ROW LEVEL SECURITY;

-- Users can only access their own cached weather data
CREATE POLICY "Users can access own weather cache" ON weather_cache
FOR ALL USING (auth.uid() = user_id);

-- Public read access for fresh weather data (within expiry)
CREATE POLICY "Public read access for fresh weather data" ON weather_cache
FOR SELECT USING (expires_at > NOW());

-- Create indexes for performance
CREATE INDEX idx_weather_cache_key ON weather_cache(cache_key);
CREATE INDEX idx_weather_cache_location ON weather_cache(location_lat, location_lng);
CREATE INDEX idx_weather_cache_expires ON weather_cache(expires_at);
CREATE INDEX idx_weather_cache_user_type ON weather_cache(user_id, weather_type);

-- Function to clean up expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_weather_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM weather_cache WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a cron job to clean up expired entries every hour
-- Note: This requires the pg_cron extension to be enabled
-- SELECT cron.schedule('cleanup-weather-cache', '0 * * * *', 'SELECT cleanup_expired_weather_cache();'); 
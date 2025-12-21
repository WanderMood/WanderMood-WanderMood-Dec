-- Create table for caching place reviews to reduce API calls
CREATE TABLE IF NOT EXISTS place_reviews_cache (
  place_id TEXT PRIMARY KEY,
  reviews JSONB NOT NULL DEFAULT '[]'::jsonb,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_place_reviews_cache_expires_at 
  ON place_reviews_cache(expires_at);

-- Create index for place_id lookups
CREATE INDEX IF NOT EXISTS idx_place_reviews_cache_place_id 
  ON place_reviews_cache(place_id);

-- Enable RLS
ALTER TABLE place_reviews_cache ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read cached reviews (public data)
CREATE POLICY "Anyone can read cached reviews"
  ON place_reviews_cache
  FOR SELECT
  USING (true);

-- Policy: Allow anyone to insert/update (for caching)
-- Reviews are public data from Google Places API, so safe to cache publicly
CREATE POLICY "Anyone can cache reviews"
  ON place_reviews_cache
  FOR ALL
  USING (true);

-- Add comment
COMMENT ON TABLE place_reviews_cache IS 'Cache for Google Places API reviews to reduce API calls. Reviews are cached for 7 days.';


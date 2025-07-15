-- Enable the necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  preferences JSONB DEFAULT '{}',
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for Users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" 
ON users FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Users can update own data" 
ON users FOR UPDATE 
USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" 
ON users FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Moods Table
CREATE TABLE IF NOT EXISTS moods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  mood_type TEXT NOT NULL,
  intensity INTEGER CHECK (intensity BETWEEN 1 AND 10),
  notes TEXT,
  weather JSONB DEFAULT '{}',
  location GEOGRAPHY(POINT),
  activities TEXT[],
  is_shared BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for Moods
ALTER TABLE moods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own moods" 
ON moods FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can view shared moods" 
ON moods FOR SELECT 
USING (is_shared = true);

-- Places Table
CREATE TABLE IF NOT EXISTS places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  location GEOGRAPHY(POINT) NOT NULL,
  address TEXT,
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  mood_tags TEXT[],
  weather_suitability TEXT[],
  activities TEXT[],
  photos TEXT[],
  rating DECIMAL(3,1),
  opening_hours JSONB,
  price_level INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for Places
ALTER TABLE places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for places" 
ON places FOR SELECT 
USING (true);

CREATE POLICY "Admin can manage places" 
ON places FOR ALL 
USING (auth.uid() IN (
  SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' = 'admin'
));

-- User_Places Table (Favorites and history)
CREATE TABLE IF NOT EXISTS user_places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  place_id UUID REFERENCES places(id) NOT NULL,
  is_favorite BOOLEAN DEFAULT false,
  visit_count INTEGER DEFAULT 0,
  last_visited TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, place_id)
);

-- Row Level Security for User_Places
ALTER TABLE user_places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own place relationships" 
ON user_places FOR ALL 
USING (auth.uid() = user_id);

-- Weather Data Table
CREATE TABLE IF NOT EXISTS weather_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location GEOGRAPHY(POINT) NOT NULL,
  city TEXT NOT NULL,
  country TEXT,
  temperature DECIMAL(5,2),
  conditions TEXT,
  icon TEXT,
  humidity INTEGER,
  wind_speed DECIMAL(5,2),
  forecast JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '2 hours')
);

-- Row Level Security for Weather Data
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for weather data" 
ON weather_data FOR SELECT 
USING (true);

CREATE POLICY "Admin can manage weather data" 
ON weather_data FOR ALL 
USING (auth.uid() IN (
  SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' = 'admin'
));

-- Activities Table
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  emoji TEXT,
  category TEXT,
  is_custom BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for Activities
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for activities" 
ON activities FOR SELECT 
USING (true);

CREATE POLICY "Users can manage custom activities" 
ON activities FOR ALL 
USING (auth.uid() = created_by AND is_custom = true);

-- Bookings Table
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  place_id UUID REFERENCES places(id) NOT NULL,
  booking_date DATE NOT NULL,
  quantity INTEGER NOT NULL,
  option_type TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL,
  payment_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for Bookings
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own bookings" 
ON bookings FOR ALL 
USING (auth.uid() = user_id);

-- User Settings Table
CREATE TABLE IF NOT EXISTS user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  theme TEXT DEFAULT 'system',
  language TEXT DEFAULT 'en',
  notifications_enabled BOOLEAN DEFAULT TRUE,
  location_tracking_enabled BOOLEAN DEFAULT TRUE,
  offline_mode_enabled BOOLEAN DEFAULT TRUE,
  preferred_units TEXT DEFAULT 'metric',
  auto_weather_update BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security for User Settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own settings" 
ON user_settings FOR ALL 
USING (auth.uid() = user_id);

-- Indexes for better performance
CREATE INDEX idx_moods_user_id ON moods(user_id);
CREATE INDEX idx_moods_created_at ON moods(created_at);
CREATE INDEX idx_places_city ON places(city);
CREATE INDEX idx_places_location ON places USING GIST(location);
CREATE INDEX idx_places_mood_tags ON places USING GIN(mood_tags);
CREATE INDEX idx_user_places_user_id ON user_places(user_id);
CREATE INDEX idx_user_places_place_id ON user_places(place_id);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_date ON bookings(booking_date);
CREATE INDEX idx_weather_data_location ON weather_data USING GIST(location);
CREATE INDEX idx_weather_data_city ON weather_data(city);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at columns
CREATE TRIGGER set_timestamp_users
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_places
BEFORE UPDATE ON places
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_bookings
BEFORE UPDATE ON bookings
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_user_settings
BEFORE UPDATE ON user_settings
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp(); 
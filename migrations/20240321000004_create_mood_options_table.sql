-- Create mood_options table
CREATE TABLE mood_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  label TEXT NOT NULL,
  emoji TEXT NOT NULL,
  description TEXT,
  energy_level INTEGER NOT NULL,
  color TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE mood_options ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Everyone can view mood options"
  ON mood_options FOR SELECT
  TO PUBLIC
  USING (true);

-- Insert default moods
INSERT INTO mood_options (label, emoji, description, energy_level, color) VALUES
  ('Energetic', '⚡', 'Full of energy and ready for anything', 5, '#FFD700'),
  ('Peaceful', '🌅', 'Calm and tranquil', 2, '#87CEEB'),
  ('Adventurous', '🚀', 'Ready to explore and try new things', 4, '#FF4500'),
  ('Creative', '🎨', 'Feeling artistic and imaginative', 3, '#9370DB'),
  ('Relaxed', '😌', 'Taking it easy', 1, '#98FB98'),
  ('Excited', '🎉', 'Thrilled about something', 5, '#FF69B4'),
  ('Focused', '🎯', 'Concentrated and determined', 4, '#4169E1'),
  ('Playful', '🎮', 'In a fun mood', 3, '#FF7F50'),
  ('Mindful', '🧘', 'Present and aware', 2, '#DDA0DD'),
  ('Cozy', '🏡', 'Comfortable and content', 1, '#DEB887');

-- Create updated_at trigger
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON mood_options
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 
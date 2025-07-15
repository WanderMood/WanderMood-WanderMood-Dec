-- Create mood_options table for global mood options
CREATE TABLE mood_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  label TEXT NOT NULL UNIQUE,
  emoji TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_mood_options_active_order ON mood_options(is_active, display_order);

-- Insert the 12 mood options from the current hardcoded data
INSERT INTO mood_options (label, emoji, color_hex, display_order) VALUES
  ('Adventure', '⛰️', '#FFC266', 1),
  ('Relaxed', '😌', '#90CDF4', 2),
  ('Energetic', '⚡', '#FFD54F', 3),
  ('Excited', '🎉', '#CE93D8', 4),
  ('Surprise', '🎁', '#F8B195', 5),
  ('Foody', '🍎', '#FF8A65', 6),
  ('Festive', '🎭', '#81C784', 7),
  ('Mindful', '☘️', '#66BB6A', 8),
  ('Family fun', '👨‍👩‍👧‍👦', '#7986CB', 9),
  ('Creative', '💡', '#FFEE58', 10),
  ('Freactives', '👨‍👩‍👧', '#4FC3F7', 11),
  ('Luxurious', '💎', '#9575CD', 12);

-- Enable RLS (though this table will be publicly readable)
ALTER TABLE mood_options ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access
CREATE POLICY "Anyone can view mood options"
  ON mood_options FOR SELECT
  USING (true);

-- Create policy for admin-only modifications (optional)
CREATE POLICY "Only admins can modify mood options"
  ON mood_options FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Create updated_at function if it doesn't exist
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create updated_at trigger
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON mood_options
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 
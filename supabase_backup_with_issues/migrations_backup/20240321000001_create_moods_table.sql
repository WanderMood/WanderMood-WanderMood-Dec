-- Create moods table
CREATE TABLE moods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  emoji TEXT NOT NULL,
  energy_level INTEGER,
  note TEXT,
  activities JSONB DEFAULT '[]'::jsonb,
  is_shared BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE moods ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own moods"
  ON moods FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own moods"
  ON moods FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own moods"
  ON moods FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own moods"
  ON moods FOR DELETE
  USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON moods
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 
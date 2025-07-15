-- Create activities table
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  emoji TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  is_custom BOOLEAN DEFAULT false,
  last_used TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Everyone can view activities"
  ON activities FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create custom activities"
  ON activities FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND is_custom = true);

CREATE POLICY "Users can update their custom activities"
  ON activities FOR UPDATE
  USING (auth.role() = 'authenticated' AND is_custom = true);

CREATE POLICY "Users can delete their custom activities"
  ON activities FOR DELETE
  USING (auth.role() = 'authenticated' AND is_custom = true);

-- Create updated_at trigger
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON activities
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 
-- Create chat_messages table
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_from_user BOOLEAN NOT NULL DEFAULT true,
  context JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own chat messages"
  ON chat_messages FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own chat messages"
  ON chat_messages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chat messages"
  ON chat_messages FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chat messages"
  ON chat_messages FOR DELETE
  USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 
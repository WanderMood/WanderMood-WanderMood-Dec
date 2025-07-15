-- Check if the table exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_preferences') THEN
    -- Create user_preferences table
    CREATE TABLE public.user_preferences (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      dark_mode BOOLEAN DEFAULT false,
      use_system_theme BOOLEAN DEFAULT true,
      use_animations BOOLEAN DEFAULT true,
      show_confetti BOOLEAN DEFAULT true,
      show_progress BOOLEAN DEFAULT true,
      trip_reminders BOOLEAN DEFAULT true,
      weather_updates BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      UNIQUE(user_id)
    );

    -- Add updated_at trigger
    CREATE TRIGGER handle_updated_at
      BEFORE UPDATE ON public.user_preferences
      FOR EACH ROW
      EXECUTE FUNCTION handle_updated_at();

    -- Add RLS policies
    ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

    -- Allow users to read their own preferences
    CREATE POLICY "Users can read their own preferences"
      ON public.user_preferences
      FOR SELECT
      USING (auth.uid() = user_id);

    -- Allow users to insert their own preferences
    CREATE POLICY "Users can insert their own preferences"
      ON public.user_preferences
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    -- Allow users to update their own preferences
    CREATE POLICY "Users can update their own preferences"
      ON public.user_preferences
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$; 
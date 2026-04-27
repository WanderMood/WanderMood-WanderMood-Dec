-- Let partners see each other's activity notes without refreshing the app.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'group_activity_notes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.group_activity_notes;
  END IF;
END $$;

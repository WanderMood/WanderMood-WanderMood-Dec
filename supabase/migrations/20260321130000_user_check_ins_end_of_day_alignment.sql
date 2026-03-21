-- Align public.user_check_ins with app inserts (CheckInService + EndOfDayCheckInService).
-- Run via `supabase db push` or paste into SQL Editor if the save fails with "column does not exist".

-- 1) Legacy name → app name
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_check_ins' AND column_name = 'activities_completed'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_check_ins' AND column_name = 'activities'
  ) THEN
    ALTER TABLE public.user_check_ins RENAME COLUMN activities_completed TO activities;
  END IF;
END $$;

-- 2) Columns the app expects (20250101000000_create_user_check_ins.sql)
ALTER TABLE public.user_check_ins
  ADD COLUMN IF NOT EXISTS activities TEXT[] DEFAULT '{}';

ALTER TABLE public.user_check_ins
  ADD COLUMN IF NOT EXISTS reactions TEXT[] DEFAULT '{}';

ALTER TABLE public.user_check_ins
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

ALTER TABLE public.user_check_ins
  ADD COLUMN IF NOT EXISTS timestamp TIMESTAMPTZ;

-- Backfill timestamp from created_at when missing
UPDATE public.user_check_ins
SET timestamp = COALESCE(timestamp, created_at, NOW())
WHERE timestamp IS NULL;

ALTER TABLE public.user_check_ins
  ALTER COLUMN timestamp SET DEFAULT NOW();

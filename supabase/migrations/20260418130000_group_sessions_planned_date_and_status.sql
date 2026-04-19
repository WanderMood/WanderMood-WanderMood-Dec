-- Group planning: add planned_date and expand status CHECK for day_proposed/day_confirmed
-- (used by the Mood Match day picker → reveal → time picker flow).

-- 1. Add planned_date column (YYYY-MM-DD stored as DATE for owner's chosen day).
ALTER TABLE public.group_sessions
  ADD COLUMN IF NOT EXISTS planned_date date;

-- 2. Expand status CHECK to include day_proposed and day_confirmed.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'group_sessions_status_check'
      AND conrelid = 'public.group_sessions'::regclass
  ) THEN
    ALTER TABLE public.group_sessions
      DROP CONSTRAINT group_sessions_status_check;
  END IF;
END $$;

ALTER TABLE public.group_sessions
  ADD CONSTRAINT group_sessions_status_check
  CHECK (status IN (
    'waiting',
    'generating',
    'ready',
    'day_proposed',
    'day_confirmed',
    'expired',
    'error'
  ));

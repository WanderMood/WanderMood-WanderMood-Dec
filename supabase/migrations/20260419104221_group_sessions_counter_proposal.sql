-- Mood Match: persist guest counter-proposals on group_sessions so the
-- session OWNER can recover the "X proposed a different day, accept?" modal
-- after a cold start / push-tap (the realtime stream only delivers NEW
-- inserts after subscribe, so without DB persistence the owner silently
-- misses counter proposals).

-- 1. Columns: who proposed and which slot ('morning' | 'afternoon' |
--    'evening' | 'whole_day'). `planned_date` already exists from
--    20260418130000 and stores the proposed date.
ALTER TABLE public.group_sessions
  ADD COLUMN IF NOT EXISTS proposed_slot text;

ALTER TABLE public.group_sessions
  ADD COLUMN IF NOT EXISTS proposed_by_user_id uuid;

-- 2. Expand status CHECK to include `day_counter_proposed`. Done in a
--    DO block + IF EXISTS so re-runs are safe and old environments
--    that never had a CHECK constraint don't blow up.
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
    'day_counter_proposed',
    'day_confirmed',
    'expired',
    'error'
  ));

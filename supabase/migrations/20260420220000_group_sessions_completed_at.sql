-- 20260420220000_group_sessions_completed_at.sql
--
-- Product-level "session complete" signal for Mood Match.
--
-- Today the hub distinguishes "Active" vs "Completed" using a per-user lookup
-- into `scheduled_activities`, which is fine for UX but gives us no session-
-- level visibility into which sessions actually landed in anyone's My Day
-- (useful for funnel analytics and for admin queries that want to surface
-- "completed" sessions even when the row owner isn't the logged-in user).
--
-- `completed_at` is set the first time ANY member taps "Add to My Day" on the
-- Mood Match result screen. It's a once-only stamp — later saves keep the
-- original timestamp via COALESCE.
--
-- The column is deliberately nullable and indexed partially (only non-null
-- rows) so we keep the write path cheap and index small.

BEGIN;

ALTER TABLE public.group_sessions
  ADD COLUMN IF NOT EXISTS completed_at timestamptz;

COMMENT ON COLUMN public.group_sessions.completed_at IS
  'Set the first time a member commits the Mood Match plan to their My Day (null until then). Never updated after the first write — see saveMoodMatchPlanToMyDayForAllMembers.';

CREATE INDEX IF NOT EXISTS idx_group_sessions_completed_at
  ON public.group_sessions (completed_at)
  WHERE completed_at IS NOT NULL;

COMMIT;

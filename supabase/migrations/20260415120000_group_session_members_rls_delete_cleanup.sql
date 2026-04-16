-- Fix infinite RLS recursion on group_session_members (42P17).
-- Add delete policies for cancel flow; expire stale waiting sessions.

-- One-time cleanup: mark old waiting sessions as expired
UPDATE public.group_sessions
SET status = 'expired',
    updated_at = now()
WHERE status = 'waiting'
  AND expires_at < now();

DROP POLICY IF EXISTS "group_session_members_select_peers" ON public.group_session_members;

-- Read own row OR any row in a session the user belongs to (subquery only touches own rows → no recursion)
CREATE POLICY "group_session_members_select_peers"
  ON public.group_session_members
  FOR SELECT
  USING (
    user_id = (SELECT auth.uid())
    OR session_id IN (
      SELECT m.session_id
      FROM public.group_session_members m
      WHERE m.user_id = (SELECT auth.uid())
    )
  );

-- Joiner can leave; removes self from session
CREATE POLICY "group_session_members_delete_own"
  ON public.group_session_members
  FOR DELETE
  USING (user_id = (SELECT auth.uid()));

-- Host can delete the whole session (cascades members + plans)
CREATE POLICY "group_sessions_delete_creator"
  ON public.group_sessions
  FOR DELETE
  USING (created_by = (SELECT auth.uid()));

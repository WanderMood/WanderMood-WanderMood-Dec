-- Group planning RLS: remove any policy recursion (42P17).
-- Uses a SECURITY DEFINER helper with row_security off so policies don't self-join.

-- Helper: true if current user is a member of the session.
CREATE OR REPLACE FUNCTION public.is_group_session_member(p_session_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_session_members m
    WHERE m.session_id = p_session_id
      AND m.user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_group_session_member(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_group_session_member(uuid) TO authenticated;

-- Drop old policies that can recurse via nested selects.
DROP POLICY IF EXISTS "group_sessions_select_member" ON public.group_sessions;
DROP POLICY IF EXISTS "group_sessions_update_member" ON public.group_sessions;
DROP POLICY IF EXISTS "group_plans_select_member" ON public.group_plans;
DROP POLICY IF EXISTS "group_plans_insert_member" ON public.group_plans;
DROP POLICY IF EXISTS "group_session_members_select_peers" ON public.group_session_members;

-- Sessions: creator or any member can read
CREATE POLICY "group_sessions_select_member"
  ON public.group_sessions
  FOR SELECT
  USING (
    created_by = auth.uid()
    OR public.is_group_session_member(id)
  );

-- Sessions: members may update
CREATE POLICY "group_sessions_update_member"
  ON public.group_sessions
  FOR UPDATE
  USING (public.is_group_session_member(id))
  WITH CHECK (public.is_group_session_member(id));

-- Members: any member can read all peers in the same session
CREATE POLICY "group_session_members_select_peers"
  ON public.group_session_members
  FOR SELECT
  USING (public.is_group_session_member(session_id));

-- Plans: any member can read/insert
CREATE POLICY "group_plans_select_member"
  ON public.group_plans
  FOR SELECT
  USING (public.is_group_session_member(session_id));

CREATE POLICY "group_plans_insert_member"
  ON public.group_plans
  FOR INSERT
  WITH CHECK (public.is_group_session_member(session_id));


-- Group mood planning: shared sessions, member moods, generated plan (v1).
-- Apply in Supabase SQL editor or via `supabase db push` after review.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.group_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title text,
  join_code text NOT NULL,
  status text NOT NULL DEFAULT 'waiting'
    CHECK (status IN ('waiting', 'generating', 'ready', 'expired', 'error')),
  max_members integer NOT NULL DEFAULT 2
    CHECK (max_members >= 2 AND max_members <= 8),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT group_sessions_join_code_unique UNIQUE (join_code)
);

CREATE TABLE IF NOT EXISTS public.group_session_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.group_sessions (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  mood_tag text,
  submitted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT group_session_members_session_user_unique UNIQUE (session_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_session_members_session_id
  ON public.group_session_members (session_id);

CREATE TABLE IF NOT EXISTS public.group_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL UNIQUE REFERENCES public.group_sessions (id) ON DELETE CASCADE,
  plan_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.group_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_session_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_plans ENABLE ROW LEVEL SECURITY;

-- Sessions: members (or creator) can read
CREATE POLICY "group_sessions_select_member"
  ON public.group_sessions
  FOR SELECT
  USING (
    created_by = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1
 FROM public.group_session_members m
      WHERE m.session_id = group_sessions.id
        AND m.user_id = (SELECT auth.uid())
    )
  );

-- Members may update session (status / timestamps) — v1 simplicity; tighten later if needed
CREATE POLICY "group_sessions_update_member"
  ON public.group_sessions
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM public.group_session_members m
      WHERE m.session_id = group_sessions.id
        AND m.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.group_session_members m
      WHERE m.session_id = group_sessions.id
        AND m.user_id = (SELECT auth.uid())
    )
  );

-- group_session_members: read all rows for same session if you are in that session
CREATE POLICY "group_session_members_select_peers"
  ON public.group_session_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.group_session_members m
      WHERE m.session_id = group_session_members.session_id
        AND m.user_id = (SELECT auth.uid())
    )
  );

-- Only RPC join/create inserts members in v1; allow self row update for mood
CREATE POLICY "group_session_members_update_own_mood"
  ON public.group_session_members
  FOR UPDATE
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- Plans: any session member can read
CREATE POLICY "group_plans_select_member"
  ON public.group_plans
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.group_session_members m
      WHERE m.session_id = group_plans.session_id
        AND m.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "group_plans_insert_member"
  ON public.group_plans
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.group_session_members m
      WHERE m.session_id = group_plans.session_id
        AND m.user_id = (SELECT auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- RPC: create session + creator membership (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_group_session(p_title text DEFAULT NULL)
RETURNS TABLE (session_id uuid, join_code text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_sid uuid;
  v_code text;
  attempts int := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  LOOP
    v_code := upper(substring(replace(gen_random_uuid()::text, '-', '') FROM 1 FOR 6));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.group_sessions g WHERE g.join_code = v_code);
    attempts := attempts + 1;
    IF attempts > 20 THEN
      RAISE EXCEPTION 'Could not allocate join code';
    END IF;
  END LOOP;

  INSERT INTO public.group_sessions (created_by, title, join_code)
  VALUES (v_uid, NULLIF(trim(p_title), ''), v_code)
  RETURNING id INTO v_sid;

  INSERT INTO public.group_session_members (session_id, user_id)
  VALUES (v_sid, v_uid);

  RETURN QUERY SELECT v_sid, v_code;
END;
$$;

REVOKE ALL ON FUNCTION public.create_group_session(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_group_session(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- RPC: join by code (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.join_group_session(p_join_code text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_sid uuid;
  rec public.group_sessions%ROWTYPE;
  m_count int;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_join_code IS NULL OR length(trim(p_join_code)) < 4 THEN
    RAISE EXCEPTION 'Invalid code';
  END IF;

  SELECT * INTO rec
  FROM public.group_sessions
  WHERE join_code = upper(trim(p_join_code))
    AND expires_at > now()
    AND status IN ('waiting', 'generating')
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session not found or expired';
  END IF;

  v_sid := rec.id;

  IF EXISTS (
    SELECT 1 FROM public.group_session_members m
    WHERE m.session_id = v_sid AND m.user_id = v_uid
  ) THEN
    RETURN v_sid;
  END IF;

  SELECT count(*)::int INTO m_count  FROM public.group_session_members
  WHERE session_id = v_sid;

  IF m_count >= rec.max_members THEN
    RAISE EXCEPTION 'Session is full';
  END IF;

  INSERT INTO public.group_session_members (session_id, user_id)
  VALUES (v_sid, v_uid);

  RETURN v_sid;
END;
$$;

REVOKE ALL ON FUNCTION public.join_group_session(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_group_session(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- Realtime (optional; safe to run if publication exists)
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.group_session_members;
EXCEPTION
  WHEN duplicate_object THEN NULL;
  WHEN undefined_object THEN NULL;
END;
$$;

-- Per-user (or IP) per-minute rate limits + API invocation log for admin analytics.
-- Edge Functions call edge_rate_limit_consume + insert api_invocations via service role.

CREATE TABLE IF NOT EXISTS public.api_rate_buckets (
  id BIGSERIAL PRIMARY KEY,
  user_key TEXT NOT NULL,
  function_slug TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  request_count INT NOT NULL DEFAULT 0,
  UNIQUE (user_key, function_slug, window_start)
);

CREATE INDEX IF NOT EXISTS api_rate_buckets_lookup_idx
  ON public.api_rate_buckets (user_key, function_slug, window_start DESC);

CREATE TABLE IF NOT EXISTS public.api_invocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_key TEXT NOT NULL,
  function_slug TEXT NOT NULL,
  operation TEXT,
  http_status INT NOT NULL,
  duration_ms INT NOT NULL DEFAULT 0,
  error_snippet TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS api_invocations_created_at_idx ON public.api_invocations (created_at DESC);
CREATE INDEX IF NOT EXISTS api_invocations_slug_created_idx ON public.api_invocations (function_slug, created_at DESC);
CREATE INDEX IF NOT EXISTS api_invocations_status_idx ON public.api_invocations (http_status, created_at DESC);

ALTER TABLE public.api_rate_buckets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_invocations ENABLE ROW LEVEL SECURITY;

-- No policies: only service role (bypasses RLS) writes; anon cannot read.

CREATE OR REPLACE FUNCTION public.edge_rate_limit_consume(
  p_user_key TEXT,
  p_function_slug TEXT,
  p_max_per_minute INT
) RETURNS TABLE(allowed BOOLEAN, current_count INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  w timestamptz := date_trunc('minute', timezone('utc', now()));
  c int;
BEGIN
  INSERT INTO public.api_rate_buckets (user_key, function_slug, window_start, request_count)
  VALUES (p_user_key, p_function_slug, w, 1)
  ON CONFLICT (user_key, function_slug, window_start)
  DO UPDATE SET request_count = public.api_rate_buckets.request_count + 1
  RETURNING request_count INTO c;

  allowed := (c <= p_max_per_minute);
  current_count := c;
  RETURN NEXT;
END;
$$;

REVOKE ALL ON FUNCTION public.edge_rate_limit_consume(TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.edge_rate_limit_consume(TEXT, TEXT, INT) TO service_role;

COMMENT ON TABLE public.api_invocations IS 'Edge Function request log; written by Supabase Edge (service role).';
COMMENT ON FUNCTION public.edge_rate_limit_consume IS 'Atomic per-minute counter; returns allowed if count <= max after increment.';

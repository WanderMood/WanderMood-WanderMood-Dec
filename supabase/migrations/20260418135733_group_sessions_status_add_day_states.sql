-- Noop: this version was applied directly on production (Supabase dashboard
-- or earlier MCP run) before being added to the local repo. The actual DDL --
-- expanding `public.group_sessions.status` to include the day_proposed /
-- day_confirmed states -- already lives in the local file
-- 20260418130000_group_sessions_planned_date_and_status.sql, which is
-- idempotent. This stub exists so local history matches
-- supabase_migrations.schema_migrations on the remote and `supabase db push`
-- / `db pull` stay clean.
SELECT 1;

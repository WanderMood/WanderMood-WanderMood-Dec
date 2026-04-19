-- Noop: this version was applied directly on production (Supabase dashboard)
-- to expand the type CHECK constraint on public.realtime_events with the
-- new notification event types (push / mood-match / day-proposal flow). The
-- noop sibling 20260419140000_notifications_types_and_push_tokens.sql in
-- this folder documents the same change. This stub exists so local history
-- lines up with supabase_migrations.schema_migrations on the remote.
SELECT 1;

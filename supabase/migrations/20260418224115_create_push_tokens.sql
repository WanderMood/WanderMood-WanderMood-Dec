-- Noop: this version was applied directly on production (Supabase dashboard)
-- to create public.push_tokens (FCM/APNs token store used by the
-- push-notify Edge Function and lib/services/push_notification_service.dart).
-- The noop sibling 20260419140000_notifications_types_and_push_tokens.sql in
-- this folder documents the same change. This stub exists so local history
-- lines up with supabase_migrations.schema_migrations on the remote.
SELECT 1;

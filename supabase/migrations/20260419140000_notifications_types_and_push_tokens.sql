-- Noop: notification-related DDL is already applied on production.
-- realtime_events type CHECK expansion and public.push_tokens exist from earlier
-- remote migrations (e.g. 20260418220002, 20260418224115). This file remains so
-- local history stays explicit and nobody re-adds duplicate CREATE/ALTER here.
SELECT 1;

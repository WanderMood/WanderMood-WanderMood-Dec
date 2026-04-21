-- 20260420210000_group_plans_plan_data_version.sql
--
-- Add optimistic concurrency control to `public.group_plans.plan_data`.
--
-- Why this matters (the "last-write-wins" bug):
-- -------------------------------------------------------------------------
-- Mood Match writes plan_data from BOTH sides of a session (owner + guest)
-- and the `mergePlanData` helper does a read-modify-write against the whole
-- jsonb blob. If owner and guest fire two merges at roughly the same time
-- (e.g. owner confirms slot X while guest proposes a swap on slot Y), the
-- second write silently clobbers the first because they both `SELECT`
-- the same snapshot and then `UPDATE` with their merged result.
--
-- We add `plan_data_version`:
--   - Starts at 0.
--   - The Dart repository increments it on every update with a conditional
--     UPDATE (where plan_data_version = <snapshot>). If 0 rows were updated
--     we know someone else wrote in between and we retry the merge.
--   - Pure DB-native — no CRDT, no RPC, no extra RLS policy.

BEGIN;

ALTER TABLE public.group_plans
  ADD COLUMN IF NOT EXISTS plan_data_version integer NOT NULL DEFAULT 0;

-- Belt-and-suspenders: ensure existing rows have the default set (older
-- Postgres image versions occasionally leave nulls on ADD COLUMN DEFAULT
-- when there are large tables behind a migration lock).
UPDATE public.group_plans
SET plan_data_version = 0
WHERE plan_data_version IS NULL;

COMMENT ON COLUMN public.group_plans.plan_data_version IS
  'Optimistic lock token bumped on every plan_data update by the Mood Match repository. Conditional UPDATE WHERE plan_data_version = <snapshot>.';

COMMIT;

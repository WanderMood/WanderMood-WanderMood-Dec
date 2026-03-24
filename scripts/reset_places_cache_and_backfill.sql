-- One-time maintenance script for richer place-linked cards.
-- Run in Supabase SQL editor with service role privileges.
--
-- What it does:
-- 1) Clears stale Explore cache rows in places_cache.
-- 2) Backfills scheduled_activities.place_id from activity_id patterns where possible.
-- 3) Prints diagnostics for missing place links.

begin;

-- 1) Clear Explore cache rows so fresh strict-quality cards are generated.
delete from places_cache
where request_type = 'explore'
   or cache_key like 'explore_%';

-- 2) Backfill place_id from known activity_id formats:
--    - place_google_<PLACEID>_<timestamp>
--    - activity_<timestamp>_google_<PLACEID>
update scheduled_activities
set place_id = regexp_replace(activity_id, '^place_(google_[^_]+(?:_[^_]+)*)_\\d+$', '\1')
where (place_id is null or trim(place_id) = '')
  and activity_id ~ '^place_google_';

update scheduled_activities
set place_id = regexp_replace(activity_id, '^activity_\\d+_(google_[^_]+(?:_[^_]+)*)$', '\1')
where (place_id is null or trim(place_id) = '')
  and activity_id ~ '^activity_\\d+_google_';

-- 3) Diagnostics
--    Keep these select statements so the operator can validate result quality.
select
  count(*) as missing_place_id_count
from scheduled_activities
where place_id is null or trim(place_id) = '';

select
  count(*) as linked_place_id_count
from scheduled_activities
where place_id is not null and trim(place_id) <> '';

commit;

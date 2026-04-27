-- Moody Hub visit celebration flag removed from app; column no longer used.
ALTER TABLE IF EXISTS public.scheduled_activities
  DROP COLUMN IF EXISTS celebration_shown;

-- Location columns for user_preferences.
-- Split out of 20250125_create_settings_tables.sql: that migration runs before
-- user_preferences exists (table is created in 20250713_195440_fix_mood_options.sql).

ALTER TABLE public.user_preferences ADD COLUMN IF NOT EXISTS auto_detect_location BOOLEAN DEFAULT TRUE;
ALTER TABLE public.user_preferences ADD COLUMN IF NOT EXISTS default_location TEXT;
ALTER TABLE public.user_preferences ADD COLUMN IF NOT EXISTS default_latitude DOUBLE PRECISION;
ALTER TABLE public.user_preferences ADD COLUMN IF NOT EXISTS default_longitude DOUBLE PRECISION;

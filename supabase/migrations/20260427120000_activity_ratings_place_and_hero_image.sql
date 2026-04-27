-- Optional denormalized fields for profile visit thumbnails and taste routing.
ALTER TABLE public.activity_ratings
  ADD COLUMN IF NOT EXISTS google_place_id text;

ALTER TABLE public.activity_ratings
  ADD COLUMN IF NOT EXISTS hero_image_url text;

COMMENT ON COLUMN public.activity_ratings.google_place_id IS 'Google Place ID when the rated stop is a place (Explore / My Day).';
COMMENT ON COLUMN public.activity_ratings.hero_image_url IS 'HTTPS or Place photo URL snapshot at review time for offline profile thumbnails.';

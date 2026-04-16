-- One profile per username, case-insensitive (app stores lowercase).
-- If this fails, dedupe: SELECT lower(trim(username)), count(*) FROM profiles
-- WHERE username IS NOT NULL AND trim(username) <> '' GROUP BY 1 HAVING count(*) > 1;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_lower_unique
ON public.profiles (lower(trim(username)))
WHERE username IS NOT NULL AND length(trim(username)) > 0;

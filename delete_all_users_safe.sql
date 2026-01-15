-- ================================================
-- SAFE DELETE ALL USERS FROM SUPABASE DATABASE
-- ================================================
-- ⚠️  WARNING: This will delete ALL user data permanently!
-- This version only deletes from tables that actually exist

-- 1. Delete from tables that exist (with error handling)

-- Delete scheduled activities (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'scheduled_activities') THEN
        DELETE FROM public.scheduled_activities;
        RAISE NOTICE 'Deleted from scheduled_activities';
    ELSE
        RAISE NOTICE 'Table scheduled_activities does not exist, skipping';
    END IF;
END $$;

-- Delete user preferences (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        DELETE FROM public.user_preferences;
        RAISE NOTICE 'Deleted from user_preferences';
    ELSE
        RAISE NOTICE 'Table user_preferences does not exist, skipping';
    END IF;
END $$;

-- Delete user profiles (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_profiles') THEN
        DELETE FROM public.user_profiles;
        RAISE NOTICE 'Deleted from user_profiles';
    ELSE
        RAISE NOTICE 'Table user_profiles does not exist, skipping';
    END IF;
END $$;

-- Delete social posts and likes (if tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'post_likes') THEN
        DELETE FROM public.post_likes;
        RAISE NOTICE 'Deleted from post_likes';
    ELSE
        RAISE NOTICE 'Table post_likes does not exist, skipping';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'social_posts') THEN
        DELETE FROM public.social_posts;
        RAISE NOTICE 'Deleted from social_posts';
    ELSE
        RAISE NOTICE 'Table social_posts does not exist, skipping';
    END IF;
END $$;

-- Delete travel plans (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'travel_plans') THEN
        DELETE FROM public.travel_plans;
        RAISE NOTICE 'Deleted from travel_plans';
    ELSE
        RAISE NOTICE 'Table travel_plans does not exist, skipping';
    END IF;
END $$;

-- Delete friendships (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'friendships') THEN
        DELETE FROM public.friendships;
        RAISE NOTICE 'Deleted from friendships';
    ELSE
        RAISE NOTICE 'Table friendships does not exist, skipping';
    END IF;
END $$;

-- Delete cached places (if tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'places_cache') THEN
        DELETE FROM public.places_cache;
        RAISE NOTICE 'Deleted from places_cache';
    ELSE
        RAISE NOTICE 'Table places_cache does not exist, skipping';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'cached_places') THEN
        DELETE FROM public.cached_places;
        RAISE NOTICE 'Deleted from cached_places';
    ELSE
        RAISE NOTICE 'Table cached_places does not exist, skipping';
    END IF;
END $$;

-- 2. Delete all users from Supabase Auth
-- This is the main deletion - auth.users always exists
DELETE FROM auth.users WHERE TRUE;

-- 3. Show final results
DO $$
DECLARE
    user_count INTEGER;
    pref_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM auth.users;
    
    -- Check preferences count only if table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        SELECT COUNT(*) INTO pref_count FROM public.user_preferences;
    ELSE
        pref_count := 0;
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DELETION COMPLETE!';
    RAISE NOTICE 'Remaining users: %', user_count;
    RAISE NOTICE 'Remaining preferences: %', pref_count;
    RAISE NOTICE '========================================';
END $$; 
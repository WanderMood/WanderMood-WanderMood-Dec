-- ================================================
-- DELETE ALL USERS FROM SUPABASE DATABASE
-- ================================================
-- ⚠️  WARNING: This will delete ALL user data permanently!
-- Run this in your Supabase SQL Editor

-- 1. Delete all user-related data from custom tables first
-- (to avoid foreign key constraint violations)

-- Delete scheduled activities
DELETE FROM public.scheduled_activities;

-- Delete user preferences
DELETE FROM public.user_preferences;

-- Delete user profiles (if exists)
DELETE FROM public.user_profiles WHERE TRUE;

-- Delete social posts and related data (if exists)
DELETE FROM public.post_likes WHERE TRUE;
DELETE FROM public.social_posts WHERE TRUE;

-- Delete travel plans (if exists)
DELETE FROM public.travel_plans WHERE TRUE;

-- Delete friendships (if exists)
DELETE FROM public.friendships WHERE TRUE;

-- Delete any cached data
DELETE FROM public.places_cache WHERE TRUE;
DELETE FROM public.cached_places WHERE TRUE;

-- 2. Delete all users from Supabase Auth
-- This will cascade delete auth-related data
DELETE FROM auth.users WHERE TRUE;

-- 3. Reset any auto-increment sequences (if applicable)
-- This ensures new users start with clean IDs

-- 4. Verify deletion
SELECT 'Users deleted successfully!' as message,
       (SELECT COUNT(*) FROM auth.users) as remaining_users,
       (SELECT COUNT(*) FROM public.user_preferences) as remaining_preferences;

-- ================================================
-- RESULT: All users and related data deleted!
-- You can now create a fresh account for testing
-- ================================================ 
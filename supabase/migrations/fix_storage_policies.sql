-- ============================================
-- FIX STORAGE POLICIES FOR AVATARS BUCKET
-- ============================================
-- This migration fixes RLS policies for the avatars bucket
-- Run this in Supabase SQL Editor if policies aren't working

-- First, drop any existing policies for avatars bucket
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;

-- Policy 1: Anyone can view/read avatar images (public bucket)
CREATE POLICY "Avatar images are publicly accessible" 
ON storage.objects
FOR SELECT 
USING (bucket_id = 'avatars');

-- Policy 2: Authenticated users can upload to avatars bucket
-- More permissive: any authenticated user can upload
-- The app will handle user-specific paths
CREATE POLICY "Authenticated users can upload avatars" 
ON storage.objects
FOR INSERT 
WITH CHECK (
  bucket_id = 'avatars' AND 
  auth.role() = 'authenticated'
);

-- Policy 3: Users can update their own avatars
-- Check if file path starts with their user ID
CREATE POLICY "Users can update their own avatar" 
ON storage.objects
FOR UPDATE 
USING (
  bucket_id = 'avatars' AND 
  auth.role() = 'authenticated' AND
  (name LIKE auth.uid()::text || '/%' OR name = auth.uid()::text || '.jpg' OR name = auth.uid()::text || '.png')
);

-- Policy 4: Users can delete their own avatars
CREATE POLICY "Users can delete their own avatar" 
ON storage.objects
FOR DELETE 
USING (
  bucket_id = 'avatars' AND 
  auth.role() = 'authenticated' AND
  (name LIKE auth.uid()::text || '/%' OR name = auth.uid()::text || '.jpg' OR name = auth.uid()::text || '.png')
);

-- ============================================
-- VERIFICATION
-- ============================================
-- After running this, verify policies exist:
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%avatar%';


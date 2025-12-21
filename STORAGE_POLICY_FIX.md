# Storage Policy Fix - Quick Guide

## Problem
Getting error: `StorageException (message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)` when uploading profile pictures.

## Solution

The storage policies need to be updated. You have two options:

### Option 1: Run SQL in Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Click on **SQL Editor** in the left sidebar

2. **Run the Fix SQL**
   - Copy and paste the SQL from `supabase/migrations/fix_storage_policies.sql`
   - Click **Run** to execute

3. **Verify Policies**
   - Go to **Storage** → **Policies**
   - You should see 4 policies for the `avatars` bucket:
     - "Avatar images are publicly accessible" (SELECT)
     - "Authenticated users can upload avatars" (INSERT)
     - "Users can update their own avatar" (UPDATE)
     - "Users can delete their own avatar" (DELETE)

### Option 2: Use the Updated Migration

The migration file `fix_missing_tables_and_columns.sql` has been updated with better policies. If you haven't run it yet, run it now.

## What Changed?

The old policy used `storage.foldername(name)[1]` which wasn't working reliably. The new policy:
- Uses `LIKE` pattern matching: `name LIKE auth.uid()::text || '/%'`
- Is more permissive for uploads (any authenticated user can upload)
- Still restricts updates/deletes to files in the user's own folder

## Test

After applying the policies, try uploading a profile picture again. It should work now!


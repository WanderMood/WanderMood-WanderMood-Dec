# Storage Bucket Setup Guide

## Profile Picture Upload Fix

The app needs a storage bucket named `avatars` in Supabase Storage to save profile pictures.

### Quick Setup (Recommended)

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Click on **Storage** in the left sidebar

2. **Create the Bucket**
   - Click **"New bucket"** button
   - **Name:** `avatars`
   - **Public bucket:** ✅ Yes (check this box)
   - **File size limit:** 5 MB (optional, but recommended)
   - **Allowed MIME types:** `image/jpeg, image/jpg, image/png, image/webp` (optional)
   - Click **"Create bucket"**

3. **Verify RLS Policies**
   - The migration SQL will automatically create the RLS policies
   - If you need to check them manually:
     - Go to Storage → Policies
     - You should see policies for:
       - Public read access
       - Authenticated users can upload/update/delete their own files

### Alternative: Supabase CLI

If you have Supabase CLI installed:

```bash
supabase storage create avatars --public
```

### Verification

After creating the bucket, try uploading a profile picture in the app. The error "Bucket not found" should be resolved.

---

## Migration Note

The migration file `fix_missing_tables_and_columns.sql` includes SQL to set up RLS policies, but **the bucket itself must be created in the Dashboard** (SQL INSERT doesn't create storage buckets).


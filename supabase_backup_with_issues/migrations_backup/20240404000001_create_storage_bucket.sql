-- Create storage bucket for profile images if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile_images', 'profile_images', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policy to allow authenticated users to upload their own profile images
CREATE POLICY "Users can upload their own profile image"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'profile_images' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to update their own profile images
CREATE POLICY "Users can update their own profile image"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'profile_images' AND
    (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'profile_images' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public access to profile images
CREATE POLICY "Profile images are publicly accessible"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile_images'); 
-- Create storage bucket for profile images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile_images',
  'profile_images',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create storage policy for profile images
CREATE POLICY "Users can upload their own profile images" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'profile_images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Profile images are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'profile_images');

CREATE POLICY "Users can update their own profile images" ON storage.objects
FOR UPDATE USING (bucket_id = 'profile_images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own profile images" ON storage.objects
FOR DELETE USING (bucket_id = 'profile_images' AND auth.uid()::text = (storage.foldername(name))[1]); 